# This app is translated from Mastering Shinywidgets
# https://mastering-shiny.org/basic-reactivity.html#reactive-expressions-1
from shiny import App, render, ui
from numpy import random
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import sys


# Style
sns.set(context="talk", style="white", font_scale=0.8)


# Load file
# ----------------------------------------------------------------------------
summary_report = "./shiny_data.csv"

inputfile = pd.read_csv(summary_report)


# ----------------------------------------------------------------------------

options = {item: item for item in list(inputfile.columns)}
options_color = {"aligner": "assembly", "tree": "tree"}
options_eval = {
    "sp": "sum of pairs (SP)",
    "n_sequences": "# sequences",
    "tc": "total column score (TC)",
    "perc_sim": "sequences avg similarity",
    "seq_length_mean": "sequence length (mean)",
}

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
                    "x axis": options_eval,
                },
                selected="n_sequences",
            ),
        ),
        ui.column(
            4,
            ui.input_select(
                "y",
                "Y axis: ",
                {
                    "y axis": options_eval,
                },
                selected="sp",
            ),
        ),
        ui.column(
            4,
            ui.input_select(
                "color",
                "color: ",
                {
                    "color": options_color,
                },
                selected="align",
            ),
        ),
        ui.column(
            4,
            ui.input_numeric("size", "dot's size: ", min=1, max=100, step=10, value=60),
        ),
    ),
    ui.row(
        ui.column(
            4, {"class": "col-md-40 col-lg-25 py-10 mx-auto text-lg-center text-left"}, ui.output_plot("scatter")
        ),
    ),
)


def server(input, output, session):
    @output
    @render.plot
    def scatter():
        plt.ylim(0, 100)
        plt.xlim(0, 100)

        x_label = options_eval[input.x()]
        y_label = options_eval[input.y()]

        ax = sns.scatterplot(data=inputfile, x=input.x(), y=input.y(), hue=input.color(), s=input.size())

        ax.set_xlabel(x_label)
        ax.set_ylabel(y_label)

        plt.legend(bbox_to_anchor=(1.05, 1), loc=3, borderaxespad=0.0)
        return ax


app = App(app_ui, server)
