FROM rocker/shiny-verse
RUN mkdir /shiny-app
COPY ./ /shiny-app/
RUN Rscript "/shiny-app/require-packages.R"
EXPOSE 3838
CMD Rscript -e 'shiny::runApp("/shiny-app/cvrp-app", port = 3838, host= "0.0.0.0")'