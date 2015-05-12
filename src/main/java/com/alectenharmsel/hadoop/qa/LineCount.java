/* 
 * Copyright 2015 Alec Ten Harmsel
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

package com.alectenharmsel.hadoop.qa;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

public class LineCount
{
    public static class Map extends Mapper<Object, Text, Text, LongWritable>
    {
        public void map(Object key, Text contents, Context context) throws IOException, InterruptedException
        {
            context.write(new Text("lc"), new LongWritable(1));
        }
    }

    public static class Reduce extends Reducer<Text, LongWritable, Text, LongWritable>
    {
        public void reduce(Text key, Iterable<LongWritable> counts, Context context) throws IOException, InterruptedException
        {
            long total = 0;

            for(LongWritable tmp:counts)
            {
                total += tmp.get();
            }

            context.write(key, new LongWritable(total));
        }
    }

    public static void main(String[] args) throws Exception
    {
        GenericOptionsParser parse = new GenericOptionsParser(new Configuration(), args);
        Configuration conf = parse.getConfiguration();

        String[] remainingArgs = parse.getRemainingArgs();
        if(remainingArgs.length != 2)
        {
            System.err.println("Usage: LineCount <input> <output>");
            System.exit(-1);
        }

        Job job = Job.getInstance(conf, "LineCount");
        job.setJarByClass(LineCount.class);

        job.setMapperClass(Map.class);
        job.setCombinerClass(Reduce.class);
        job.setReducerClass(Reduce.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(LongWritable.class);

        FileInputFormat.addInputPath(job, new Path(remainingArgs[0]));
        FileOutputFormat.setOutputPath(job, new Path(remainingArgs[1]));

        boolean success = job.waitForCompletion(true);

        int res = success ? 0 : 1;
        System.exit(res);
    }
}
