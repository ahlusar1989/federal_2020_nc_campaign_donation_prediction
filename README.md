# Windfall Challenge Response for Saran Singh Ahluwalia



## Directory Structure

| Folder                    | Description                                                                                                                                                                       |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| config                    | configuration for database connection secrets, FEC and Census API keys, and other miscellaneous authentication secrets (not included). If one would like to use the Google Cloud API or another service to replicate this work, a configuration file is highly recommended.                                                                                                                                                           |
| experimental_modelling                      | Notebooks and original data for 1) logit model with LASSO and 2) more for beginning to answer questions outlined in the exploratory analysis. The PDF output of these notebooks is in the results.                                                                                                                                                          |
| db_scripts             | used to query and build relevant queries in `results` as well as for experimentation and exposition                                                                                                                   |
| results              | 1) two CSVS representing answers to two with exploratory phase and proposed feature engineering; 2) the PDF rendering of two notebooks for a logit model to predict whether a resident in North Carolina will donate in 2020; 3) a basic characterization of the 2020 North Carolina Senate seat; 4) The challenge writeup titled: `windfall_writeup_12112022`                                                                                                                              |
  
## Requirements

1.  Python 3.7+

2. An installation for the [R](https://cran.r-project.org/doc/manuals/r-patched/R-admin.html) programming language

## Getting Started

1. First:
    ```shell
    $ unzip fec_data_analysis.zip
    $ cd fec_data_analysis
    ```

2.  Install the required packages. Using `virtualenv` is highly encouraged!

    ```shell
    $ python -m pip install --upgrade pip virtualenv
    $ python -m virtualenv .env
    $ # Windows: .env\Scripts\activate
    $ source .env/bin/activate
    $ python -m pip install -r requirements.txt
    ```

## Usage Details

1. Every notebook in the `modeling` directory outlines the source datasets and correctly references the relative path to the datasets. Assuming one has a Jupyter server running with both R and Python 3 kernel, one should be able to run each notebook. If one would like to replicate the work, please use a Jupyter kernel for Python and Google Workspace for queries. 

In `db_scripts` one can copy and paste all queries except for the queries related to the "campaign churn" idea - originally cited in the main writeup. For that one will need to first create a [dataset](https://cloud.google.com/bigquery/docs/datasets). The project I reference in those queries will differ from your project namespace. 

2. To replicate the North Carolina Senate seat study:

    ```shell
    $ cd fec_data_analysis/experimental_modelling/data/
    $ mkdir 20192020-FEC/
    $ unzip zip_files/\*.zip -d 20192020-FEC/
    ```

Finally, `cd ../nc_senate_seat_2020_exploratory_analysis/` and you are off to the races!


3. To replicate 1) the exploratory data analysis notebook (with a "v1" suffix) - `experiment_1_part_1_exploratory_analysis-v1`) and 2) logit modeling `experiment_1_part_2_lasso_logit_model_v1`: 

   * Assuming you are in the relative path `fec_data_analysis/experimental_modelling` - `cd modelling_notebooks`. From here, you should be able to run all pre-processing, ETL, and exploratory phases to regenerate the input data for the final model and the figures included in the write-up.
   * For the sake of time, I have provided the output file named `post_final_cleaned_up_final_model_data.csv`. The user will note that the writing and reading steps for this file are commented out in the notebook. You will need to uncomment those two lines to 1) re-create and 2) reproduce any additional figures or modeling steps.

4. To retrieve the source files, please refer to the notebooks listed in `preprocessing_data`. To recreate any files  - suffixed with "clean" - one will have to re-run all notebooks to retrieve and perform basic cleaning.

## Changelog

-   2022-12-10
    -   Wrote db scripts and answered main questions
    -   Started documentation
-   2022-12-11
    -   Exploratory analysis with NC Senate Race
    -   Idea and experimental design for logit model using NC
    -   Execution of experiment and draft of final writeup    
-   2022-12-12
    -   Proofreading and finalizing README  


## Additional References - outside of notebooks and Latex documents


* Cameron, A. Colin and Trivedi, P.K. (2009) Microeconometrics using stata. College Station, TX: Stata Press.

* Long, J. Scott, & Freese, Jeremy (2006). Regression Models for Categorical Dependent Variables Using Stata (Second Edition). College Station, TX: Stata Press.

* Long, J. Scott (1997). Regression Models for Categorical and Limited Dependent Variables. Thousand Oaks, CA: Sage Publications.