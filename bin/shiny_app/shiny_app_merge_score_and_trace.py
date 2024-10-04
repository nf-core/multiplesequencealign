import pandas as pd
import re

def convert_time(time_str):
    # Regular expression to match the time components
    pattern = re.compile(r'((?P<hours>\d+(\.\d+)?)h)?\s*((?P<minutes>\d+(\.\d+)?)m)?\s*((?P<seconds>\d+(\.\d+)?)s)?\s*((?P<milliseconds>\d+(\.\d+)?)ms)?')
    match = pattern.fullmatch(time_str.strip())

    if not match:
        print(time_str)
        raise ValueError("Time string is not in the correct format")

    time_components = match.groupdict(default='0')

    hours = float(time_components['hours'])
    minutes = float(time_components['minutes'])
    seconds = float(time_components['seconds'])
    milliseconds = float(time_components['milliseconds'])

    # Convert everything to minutes
    total_minutes = (hours * 60) + minutes + (seconds / 60) + (milliseconds / 60000)

    return total_minutes

def convert_memory(memory):
    # from anything to GB
    if memory is not None:
        if "GB" in memory:
            memory = memory.replace('GB', '')
        elif "MB" in memory:
            memory = memory.replace('MB', '')
            memory = float(memory)/1000
        elif "KB" in memory:
            memory = memory.replace('KB', '')
            memory = float(memory)/1000000
    return memory

def cleanTrace(trace):
    # Update trace file
    def extract_element(row, nelement):
        elements = row.split(':')
        return elements[nelement]

    trace["tag"] = trace.name.str.split('(', expand = True)[1].str.split(')', expand = True)[0]
    trace["id"]  = trace.tag.str.split(expand = True)[0]
    trace["args"] = trace.tag.str.split("args:", expand=True)[1]
    trace["full_name"] = trace.name.str.split('(', expand = True)[0].str.strip()
    trace["process"] = trace.full_name.apply(extract_element, nelement=-1)
    trace["subworkflow"] = trace.full_name.apply(extract_element, nelement=-2)
    trace.replace('null', pd.NA, inplace=True)
    return trace

def prep_tree_trace(trace):
    trace_trees = trace[trace["subworkflow"] == "COMPUTE_TREES"]
    # rename args to args_tree
    trace_trees.rename(columns={"args": "args_tree"}, inplace=True)
    # rename process to tree and remove _GUIDETREE
    trace_trees["tree"] = trace_trees["process"].str.replace("_GUIDETREE", "")
    # subselect only the columns we need
    trace_trees = trace_trees[["id", "args_tree", "tree", "realtime", "rss", "cpus"]]
    trace_trees.rename(columns={"realtime": "time_tree"}, inplace=True)
    trace_trees.rename(columns={"rss": "memory_tree"}, inplace=True)
    trace_trees.rename(columns={"cpus": "cpus_tree"}, inplace=True)
    trace_trees.replace('null', pd.NA, inplace=True)
    print(trace_trees)
    # remove ms from time_tree and convert it to min
    trace_trees["time_tree"] = trace_trees["time_tree"].apply(convert_time)
    # convert memory to GB
    trace_trees["memory_tree"] = trace_trees["memory_tree"].apply(convert_memory)
    return trace_trees

def prep_align_trace(trace):
    trace_align = trace[trace["subworkflow"] == "ALIGN"]
    # rename args to args_align
    trace_align.rename(columns={"args": "args_aligner"}, inplace=True)
    # rename process to align and remove _ALIGN
    trace_align["aligner"] = trace_align["process"].str.replace("_ALIGN", "")
    # subselect only the columns we need
    trace_align = trace_align[["id", "args_aligner", "aligner", "realtime", "rss", "cpus"]]
    trace_align.rename(columns={"realtime": "time_align"}, inplace=True)
    trace_align.rename(columns={"rss": "memory_align"}, inplace=True)
    trace_align.rename(columns={"cpus": "cpus_align"}, inplace=True)
    trace_align.replace('null', pd.NA, inplace=True)
    # remove ms from time_align and convert it to min
    trace_align["time_align"] = trace_align["time_align"].apply(convert_time)
    # convert memory to GB
    trace_align["memory_align"] = trace_align["memory_align"].apply(convert_memory)
    return trace_align


def merge_data_and_trace(data_file,trace_file,out_file_name):
        # read in shiny_data.csv
    data = pd.read_csv(data_file)
    # read in trace
    # check if trace file has more than 1 row
    if len(pd.read_csv(trace_file, sep='\t')) > 1:
        trace = pd.read_csv(trace_file, sep='\t')
        clean_trace = cleanTrace(trace)
        trace_trees = prep_tree_trace(clean_trace)
        trace_align = prep_align_trace(clean_trace)
        #merge data and trace_trees
        data_tree = pd.merge(data, trace_trees, on=["id", "tree", "args_tree"], how="left")
        data_tree_align = pd.merge(data_tree, trace_align, on=["id", "aligner", "args_aligner"], how="left")
        # write to file
        data_tree_align.to_csv(out_file_name, index=False)
    else:
        # write to file
        data.to_csv(out_file_name, index=False)
