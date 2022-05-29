FROM rocker/shiny-verse:4.2
RUN mkdir /shiny-app
COPY ./ /shiny-app/
WORKDIR /shiny-app
ENV RENV_VERSION 0.15.4
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"
EXPOSE 3838
RUN Rscript -e "renv::restore()"
CMD Rscript -e 'shiny::runApp("/shiny-app/cvrp-app", port = 3838, host= "0.0.0.0")'