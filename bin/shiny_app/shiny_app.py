# This app is translated from Mastering Shinywidgets
# https://mastering-shiny.org/basic-reactivity.html#reactive-expressions-1
from shiny import App, ui
from shinywidgets import output_widget, render_widget
import pandas as pd
import plotly.express as px
from pathlib import Path
import sys
import os
import shiny_app_merge_score_and_trace as ms


# Load file
# ----------------------------------------------------------------------------
summary_report = "./shiny_data_with_trace.csv"
trace = "./trace.txt"

if not os.path.exists(summary_report):
    summary_report_no_trace = "./shiny_data.csv"
    # run merge script here
    if os.path.exists(trace):
        ms.merge_data_and_trace(summary_report_no_trace, trace, summary_report)
    else:
        summary_report = summary_report_no_trace

try:
    inputfile = pd.read_csv(summary_report)
except:
    print("ERROR: file not found: ", summary_report)
    sys.exit(1)

def merge_tree_args(row):
    if str(row["tree"]) == "nan":
        return "None"
    elif str(row["args_tree"]) == "nan":
        return str(row["tree"]) + " ()"
    else:
        return str(row["tree"]) + " (" + str(row["args_tree"]) + ")"

inputfile["tree_args"] = inputfile.apply(merge_tree_args, axis=1)

def merge_aligner_args(row):
    if str(row["aligner"]) == "nan":
        return "None"
    elif str(row["args_aligner"]) == "nan":
        return str(row["aligner"]) + " ()"
    else:
        return str(row["aligner"]) + " (" + str(row["args_aligner"]) + ")"

inputfile["aligner_args"] = inputfile.apply(merge_aligner_args, axis=1)


# ----------------------------------------------------------------------------

options = {item: item for item in list(inputfile.columns)}

options_color = {"aligner": "Assembly",
                "aligner_args": "Assembly with args",
                "tree": "Tree",
                "tree_args": "Tree with args"}

options_eval_all = {
    "sp": "Sum of Pairs (SP)",
    "n_sequences": "Number of Sequences",
    "tc": "Total Column Score (TC)",
    "perc_sim": "Average Sequence Similarity (%)",
    "seqlength_mean": "Mean Sequence Length",
    "time_tree": "Tree Building Time (min)",
    "time_align": "Alignment Time (min)",
    "memory_tree": "Tree Building Memory (GB)",
    "memory_align": "Alignment Memory (GB)",
    "plddt": "Average pLDDT",
    "EVALUATED": "Evaluated iRMSD",
    "APDB": "APDB",
    "iRMSD": "iRMSD",
    "NiRMSD": "NiRMSD",
    "aligner": "Assembly",
    "aligner_args": "Assembly with args",
    "tree": "Tree",
    "tree_args": "Tree with args"
}

options_eval = {k: v for k,v in options_eval_all.items() if k in inputfile.columns}

vars_cat = ["aligner", "tree", "tree_args", "aligner_args"]

vars_long = ["tree_args", "aligner_args"]

options_theme = {
    "plotly": "Default",
    "plotly_white": "Light",
    "plotly_dark": "Dark"
}

palettes = {
    "theme_light": "pastel",
    "theme_dark": "deep",
    "theme_contrast": "bright"
}

xlims = {
    "sp": [0, 100],
    "tc": [0, 100],
    "perc_sim": [0, 100],
    "tcs": [0, 1000],
    "plddt": [0, 100]
}

app_ui = ui.page_fluid(
    # HEAD
    # Links
    ui.tags.link(
        rel="stylesheet",
        href="bootstrap.min.css"
    ),
    ui.tags.link(
        rel="stylesheet",
        href="style.css"
    ),
    ############################
    # BODY
    # Header
    ui.column(
        5,
        {"class": "col-md-10 col-lg-8 py-5 mx-auto text-lg-center text-left"},
        # Title
        ui.h1({"class": "fw-bold"},
                ui.span({"class": "text-primary"}, "nf-core/"), "multiplesequencealign"),
        # Subtitle
        ui.h2({"class": "text-muted"}, "Stats & Evaluation Explorer"),
        # input slider
    ),
    # Main body
    ui.layout_sidebar(
        # Sidebar
        ui.sidebar(
            # Mappings heading
            ui.h3("Mappings"),
            # X axis input
            ui.input_select(
                "x",
                "X axis: ",
                {
                        "X axis": options_eval,
                },
                selected="n_sequences",
            ),
            # Y axis input
            ui.input_select(
                "y",
                "Y axis: ",
                {
                    "Y axis": options_eval,
                },
                selected="sp",
            ),
            # Color input
            ui.input_select(
                "color",
                "Color: ",
                {
                    "Color": options_color,
                },
                selected="align",
            ),
            # Linear model checkbox
            ui.input_checkbox("lm", "Show linear model (scatterplot)", value=False),
            # Style heading
            ui.h3("Style"),
            # General
            ui.h4("General"),
            ui.input_select(
                "theme",
                "Theme: ",
                {
                    "Theme": options_theme,
                },
                selected="Dark"
            ),
            # Scatter plot
            ui.h4("Scatter plot"),
            # Point size input
            ui.input_numeric("size", "Point size: ", min=1, max=100, step=10, value=60)
        ),
        # Plots
        ui.navset_tab(
            ui.nav_panel(
                "Scatter plot",
                ui.column(
                    12,
                    {"class": "py-10 mx-0 text-lg-center text-left"},
                    output_widget("autoplot", width = "clamp(400px, 50vw, 800px)", height = "clamp(400px, 50vh, 600px)")
                )
            ),
            ui.nav_panel(
                "Correlation",
                ui.column(
                    12,
                    {"class": "py-10 mx-auto text-lg-center text-left"},
                    output_widget("corr", width = "clamp(400px, 50vw, 800px)", height = "clamp(300px, 50vh, 600px)")
                )
            )
        )
    )
)


def server(input, output, session):
    @output
    @render_widget
    def autoplot():
        if input.x() in vars_cat and input.y() in vars_cat: # heatmap
            return heatmap()
        elif input.x() in vars_cat: # vertical boxplot
            return boxplot_vertical()
        elif input.y() in vars_cat: # horizontal boxplot
            return boxplot_horizontal()
        else: # scatterplot
            return scatterplot()

    def heatmap():
        x = input.x()
        y = input.y()

        xtab = pd.crosstab(inputfile[x], inputfile[y])
        fig = px.imshow(xtab,
                        x = xtab.columns,
                        y = xtab.index,
                        text_auto = True)

        fig.update_layout(
            template = input.theme(),
            xaxis_title = options_eval.get(y, y),
            yaxis_title = options_eval.get(x, x),
            autosize = True
        )

        fig.update_xaxes(automargin = True)
        fig.update_yaxes(automargin = True)

        if x in vars_long or y in vars_long:
            fig.update_layout(showlegend = False)

        return fig

    def boxplot_horizontal():
        x = input.x()
        y = input.y()
        fig = px.box(inputfile.fillna(''),
                     x = x,
                     y = y,
                     color = y)

        fig.update_layout(
            template = input.theme(),
            xaxis_title = options_eval.get(x, x),
            yaxis_title = options_eval.get(y, y),
            legend_title_text = options_eval.get(y, y),
            autosize = True
        )

        fig.update_xaxes(automargin = True)
        fig.update_yaxes(automargin = True)

        if x in vars_long or y in vars_long:
            fig.update_layout(showlegend = False)

        return fig

    def boxplot_vertical():
        x = input.x()
        y = input.y()

        fig = px.box(inputfile.fillna(""),
                     x = x,
                     y = y,
                     color = x
        )

        fig.update_layout(
            template = input.theme(),
            xaxis_title=options_eval.get(x, x),
            yaxis_title=options_eval.get(y, y),
            legend_title_text=options_eval.get(x, x),
            autosize = True
        )

        fig.update_xaxes(automargin = True)
        fig.update_yaxes(automargin = True)

        if x in vars_long or y in vars_long:
            fig.update_layout(showlegend = False)

        return fig

    def scatterplot():
        x = input.x()
        y = input.y()
        color = input.color()
        size = input.size()

        fig = px.scatter(inputfile,
                         x = x,
                         y = y,
                         color = color,
                         trendline = "ols" if input.lm() else None,
                         trendline_scope = "overall")

        fig.update_traces(marker=dict(size=size/5))

        fig.update_layout(
            template = input.theme(),
            xaxis_title = options_eval.get(x, x),
            yaxis_title = options_eval.get(y, y),
            xaxis = dict(range = xlims.get(x, [0, None])),
            yaxis = dict(range = xlims.get(y, [0, None])),
            autosize = True
        )

        fig.update_xaxes(automargin = True)
        fig.update_yaxes(automargin = True)

        return fig


    @output
    @render_widget
    def corr():
        data = inputfile[list(set(options_eval.keys()) & set(inputfile.columns) - set(vars_cat))]
        corr = data.corr().fillna(0)
        xlabs = [options_eval.get(x, x) for x in corr.columns]
        ylabs = [options_eval.get(y, y) for y in corr.index]

        fig = px.imshow(corr,
                        x = xlabs,
                        y = ylabs,
                        text_auto = ".2f",
                        labels = options_eval)

        fig.update_layout(
            template = input.theme(),
            autosize = True
        )

        fig.update_xaxes(automargin = True,
                         showticklabels = False)
        fig.update_yaxes(automargin = True)

        return fig


app_dir = Path(__file__).parent
app = App(app_ui, server, static_assets = app_dir / "static")
