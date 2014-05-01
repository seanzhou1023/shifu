/**
 * Copyright [2012-2014] eBay Software Foundation
 *  
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *  
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
REGISTER '$path_jar'

SET default_parallel $num_parallel
SET mapred.job.queue.name $queue_name;
SET job.name 'shifu normalize'

DEFINE IsDataFilterOut  ml.shifu.shifu.udf.PurifyDataUDF('$source_type', '$path_model_config', '$path_column_config');
DEFINE DataFilter	    ml.shifu.shifu.udf.DataFilterUDF('$source_type', '$path_model_config', '$path_column_config', '$sampleRate', '$sampleNegOnly');
DEFINE Normalize 		ml.shifu.shifu.udf.NormalizeUDF('$source_type', '$path_model_config', '$path_column_config');

raw = LOAD '$path_raw_data' USING PigStorage('$delimiter');
raw = FILTER raw BY IsDataFilterOut(*);

filtered = FOREACH raw GENERATE FLATTEN(DataFilter(*));
filtered = FILTER filtered BY $0 IS NOT NULL;

STORE filtered INTO '$pathSelectedRawData' USING PigStorage('$delimiter', '-schema');

normalized = FOREACH filtered GENERATE FLATTEN(Normalize(*));
normalized = FILTER normalized BY $0 IS NOT NULL;

STORE normalized INTO '$pathNormalizedData' USING PigStorage('|', '-schema');

tag = FOREACH normalized GENERATE $0;
grouped = GROUP tag BY $0;
tagcnt = FOREACH grouped GENERATE group, COUNT($1);
DUMP tagcnt;