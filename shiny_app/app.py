# This app is translated from Mastering Shinywidgets
# https://mastering-shiny.org/basic-reactivity.html#reactive-expressions-1
from shiny import App, render, ui
from numpy import random
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import sys


# Style 
sns.set(context="talk", style = "white", font_scale=0.8)


# Load file 
# ----------------------------------------------------------------------------
summary_report = "/home/luisasantus/Desktop/crg_cluster/projects/nf-core-msa/outdir/summary_report/evaluation_summary_report.csv"
stats_report = "/home/luisasantus/Desktop/crg_cluster/projects/nf-core-msa/outdir/stats/stats_summary_report.csv"

summary_df = pd.read_csv(summary_report)
stats_df = pd.read_csv(stats_report)

cols_to_merge = ["id"]

inputfile = summary_df.merge(stats_df, on = cols_to_merge, how = "left")
# ----------------------------------------------------------------------------

options = {item: item for item in list(inputfile.columns)}

app_ui = ui.page_fluid(
    ui.column(
        5,
        {"class": "col-md-10 col-lg-8 py-5 mx-auto text-lg-center text-left"},
        # Title
        ui.h1("Explore the benchmarking results"),
        # input slider
    ),
    ui.row(
        {"class": "col-md-10 col-lg-8 py-5 mx-auto text-lg-center text-left"},
        ui.column(
            4,
             ui.input_select(
                "x",
                "X axis: ",
                {
                    "x axis": options,
                },
                selected = "n_sequences"
            ),
        ),
        ui.column(
            4,
             ui.input_select(
                "y",
                "Y axis: ",
                {
                    "y axis": options,
                },
                selected = "sp"
            ),
        ),
        ui.column(
            4,
             ui.input_select(
                "color",
                "color: ",
                {
                    "color": options,
                },
                selected = "family"
            ),
        )
    ),
    ui.row(
        ui.column(4,  {"class": "col-md-40 col-lg-25 py-10 mx-auto text-lg-center text-left"}, ui.output_plot("scatter")),
         
    ),
)


def server(input, output, session):



    @output
    @render.plot
    def scatter():
        plt.ylim(0, 100)
        plt.xlim(0, 100)
        ax = sns.scatterplot(data = inputfile,
                x = input.x(),
                y = input.y(), 
                hue = input.color(), 
                s = 60
                ) 
        plt.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0.)
        return ax



app = App(app_ui, server)
