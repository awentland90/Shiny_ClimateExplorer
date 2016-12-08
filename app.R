library(shiny)
library(leaflet)
library(rnoaa)

ui <- fluidPage(navbarPage(
  "Shiny Climate Explorer",
  # Station Analysis Page (Station Analysis)
  tabPanel(
    "Station Analysis",
    # Side Bar
    sidebarPanel(
      tags$small(
        paste0("You can find station IDs on the Station ID Explorer tab above")
      ),
      textInput("station_id_input", "Enter Station ID", "USW00014839"),
      dateInput('start_date',
                label = 'Select Start Date (yyyy-mm-dd):',
                value = "2010-01-01"),
      dateInput('end_date',
                label = 'Select End Date (yyyy-mm-dd):',
                value = "2010-12-31"),
      selectInput(
        "variable",
        "Variable:",
        c(
          "Precipitation (tenths of mm)" = "PRCP",
          "Maximum temperature (K)" = "TMAX",
          "Minimum temperature (K)" = "TMIN",
          "Snowfall (mm)" = "SNOW",
          "Snow depth (mm)" = "SNWD"
        )
      ),
      tags$small(
        paste0(
          "Note: The Climate Explorer's maximum time period or date range is 1 year (per the rnoaa library).",
          " Some variables/stations may not be available due to limited data and will throw the plot to an error.",
          " If an error occurs, try selecting a different variable or station."
        )
      )
    ),
    # Main Panel (Station Analysis)
    mainPanel(
      h3(textOutput("var_selected_out")),
      p(textOutput("date_range_out")),
      plotOutput("ncdcplotout", height = 400, width = 800),
      align = "center"
    )
  ),
  
  # Station ID Explorer Page
  tabPanel(
    "Station ID Explorer",
    align = "center",
    h3("Station ID Explorer"),
    p("Zoom in and click on a station to find its ID"),
    leafletOutput("ghcnd_map", height = 500)
  ),
  
  # About Page
  tabPanel(
    "About",
    h3("Background"),
    p(
      "The Shiny Climate Explorer is an R Shiny web application that summarizes"
    ),
    p(
      "various historical climatological datasets via the Global Historical Climatology Network (GHCN)"
    ),
    br(),
    p(
      "The GHCN Explorer utilizes a number of R libraries available through CRAN:"
    ),
    p(code("library(shiny)")),
    p(code("library(leaflet)")),
    p(code("library(rnoaa)")),
    br(),
    h3("Citations"),
    h5("Global Historical Climatology Network (GHCN) Data"),
    p(
      "Menne, M.J., I. Durre, B. Korzeniewski, S. McNeal, K. Thomas, X. Yin, S. Anthony, R. Ray,"
    ),
    p("R.S. Vose, B.E.Gleason, and T.G. Houston, 2012"),
    p(
      "Global Historical Climatology Network - Daily (GHCN-Daily), Version 3."
    ),
    p(
      "NOAA National Climatic Data Center. http://doi.org/10.7289/V5D21VHZ"
    ),
    br(),
    h5("rnoaa API"),
    p("Scott Chamberlain (NA). rnoaa: 'NOAA' Weather Data from R."),
    p("R package version 0.6.6. https://github.com/ropensci/rnoaa")
  )
))

server <- function(input, output, session) {
  # Point to the formatted stations CSV
  cities <-
    read.csv("data/ghcnd-stations.csv")
  
  # Create leaflet map for exploring stations
  output$ghcnd_map <- renderLeaflet({
    leaflet(cities) %>%  # Point to CSV we read in
      addTiles() %>%
      setView(lng = -98.35,
              lat = 39.50,
              zoom = 4) %>%  # Set default view
      addMarkers(
        lng = ~ LON,
        lat = ~ LAT,
        popup = ~ STATION_ID,
        clusterOptions = markerClusterOptions()  #Add markers and have station ID popup
      )
  })
  
  
  #Format station ID and incorporate reactive input of ID
  GHCN_char <- 'GHCND:'
  station_id <-
    reactive({
      input$station_id_input
    })  # Get user selected station ID
  station_selected <-
    reactive({
      paste(GHCN_char, station_id(), sep = "")
    }) # Paste together/format station ID with GHCN header needed for the function ncdc
  output$station_id_output <-
    renderText({
      input$station_id_input
    })  # Output station ID to user
  
  # Get user selected dates and format them for the ncdc function
  start_date_selected <-
    reactive({
      paste(as.character(as.Date(input$start_date[[1]], origin = "1970-01-01")))
    }) # Get start Date
  output$start_date_selected_out <-
    renderText({
      start_date_selected()
    })  # Output date selected to user
  
  end_date_selected <-
    reactive({
      paste(as.character(as.Date(input$end_date[[1]], origin = "1970-01-01")))
    }) # End end date
  output$end_date_selected_out <-
    renderText({
      end_date_selected()
    })  # Output date selected to user
  
  output$date_range_out <-
    renderText({
      paste(start_date_selected(), " to ", end_date_selected())
    })
  
  # Get user selected variable, ie. TMAX, PRCP, ect
  var_selected <- reactive({
    input$variable
  })
  output$var_selected_out <-
    renderText({
      paste(input$variable, " at station: ", input$station_id_input)
    })
  
  # Use rnoaa API and ncdc function with reactive input for station ID, datatype, start date, and end date
  out <-
    function() {
      return(
        ncdc(
          datasetid = 'GHCND',
          stationid = station_selected(),
          datatypeid = var_selected(),
          startdate = start_date_selected(),
          enddate = end_date_selected(),
          limit = 500
        )
      )
    }  # Define function for the rnoaa API function ncdc
  output$ncdcplotout <-
    renderPlot({
      ncdc_plot(out(), breaks = "1 month", dateformat = "%m/%y")
    })  # Output the plot
}
shinyApp(ui, server)
