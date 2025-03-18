library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(ggplot2)


get_city_temp <- function (lat = 54.55, lon = 9.98, 
                           Start_date = as.Date("2010-01-01"), end_date = Sys.Date() - 1 ) {
  # Construct the API URL
  url <- paste0("https://archive-api.open-meteo.com/v1/archive?latitude=", lat,
                "&longitude=", lon, "&start_date=", Start_date, "&end_date=", end_date,
                "&daily=temperature_2m_mean,rain_sum&timezone=Europe%2FBerlin")
  
  # Send the request
  response <- GET(url)
  
  # Check if successful and display the weather
  if (response$status_code == 200) {
    weather <- fromJSON(content(response, "text"))
    temp_data <- data.frame(
      Date = as.Date(weather$daily$time),
      Temperature = weather$daily$temperature_2m_mean,
      Rain = weather$daily$rain_sum
    )
    
    # Convert daily data to Monthly data
    temp_data <- temp_data %>%
      mutate(YearMonth = format(Date, "%Y-%m"))  # Create Year-Month column
    
    monthly_weather <- temp_data %>% 
      group_by(YearMonth) %>%
      summarize(
        Avg_Temperature = mean(Temperature, na.rm = TRUE),
        Total_Precipitation = sum(Rain, na.rm = TRUE)
      )
    
    return (monthly_weather)
  } else {
    cat("Error:", response$status_code, "\n")
  }
}

# Retrive the weather data for Berlin
lat <- 52.52
lon <- 13.40
Berlin_data <- get_city_temp(lat = lat, lon = lon)
Berlin_data <- Berlin_data %>% mutate(City = "Berlin")

# Retrive the weather data for Tokyo
lat <- 35.67
lon <- 139.65
Tokyo_data <- get_city_temp(lat = lat, lon = lon)
Tokyo_data <- Tokyo_data %>% mutate(City = "Tokyo")

# Retrive the weather data for NewYork
lat <- 40.71
lon <- 74.00
NY_data <- get_city_temp(lat = lat, lon = lon)
NY_data <- NY_data %>% mutate(City = "New York")

# Combine all datasets into one
weather_data <- bind_rows(Berlin_data, Tokyo_data, NY_data)

# Extract the Year and Month
weather_data$Year <- as.numeric(substr(weather_data$YearMonth, 1, 4))
weather_data$Month <- substr(weather_data$YearMonth, 6, 7)

# Filter labels to show only January (Month == "01") for selected years
selected_labels <- weather_data$YearMonth[weather_data$Year %% 5 == 0 & weather_data$Month == "01"]

### Create a grouped bar chart
ggplot(weather_data, aes(x = YearMonth, y = Avg_Temperature, fill = City)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_x_discrete(breaks = selected_labels) +  # Show only January of 2010, 2015, 2020, 2025
  labs(title = "Average Monthly Temperature Comparison", x = "Year-Month", y = "Avg Temperature (°C)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate labels for readability

### Scatter plot: Temperature vs. Total Precipitation
ggplot(weather_data, aes(x = Avg_Temperature, y = Total_Precipitation, color = City)) +
  geom_point(alpha = 0.7) +  # Scatter plot points with transparency
  labs(title = "Temperature vs. Total Precipitation",
       x = "Average Temperature (°C)",
       y = "Total Precipitation (mm)") +
  theme_minimal() +
  theme(legend.position = "top")  # Move legend to the top

### Plot temperature changes for a city over time
## Berlin
# Convert YearMonth to a proper date format
Berlin_data <- Berlin_data %>%
  mutate(YearMonth = as.Date(paste0(YearMonth, "-01"))) 

# Plot temperature trend over time for Berlin
ggplot(Berlin_data, aes(x = YearMonth, y = Avg_Temperature, group = 1)) +
  geom_line(color = "blue", size = 1) +  # Blue line for temperature trend
  geom_smooth(method = "lm", color = "red", linetype = "dashed", size = 1) +  # Trend line
  labs(title = "Temperature Changes Over Time (Berlin)",
       x = "Year-Month",
       y = "Average Temperature (°C)") +
  theme_minimal() +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y")  # Show labels every 5 years

## Tokyo
Tokyo_data <- Tokyo_data %>%
  mutate(YearMonth = as.Date(paste0(YearMonth, "-01")))

# Plot temperature trend over time for Berlin
ggplot(Tokyo_data, aes(x = YearMonth, y = Avg_Temperature, group = 1)) +
  geom_line(color = "green", size = 1) +  # Blue line for temperature trend
  geom_smooth(method = "lm", color = "red", linetype = "dashed", size = 1) +  # Trend line
  labs(title = "Temperature Changes Over Time (Tokyo)",
       x = "Year-Month",
       y = "Average Temperature (°C)") +
  theme_minimal() +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y")  # Show labels every 5 years

## New York
NY_data <- NY_data %>%
  mutate(YearMonth = as.Date(paste0(YearMonth, "-01")))

# Plot temperature trend over time for Berlin
ggplot(NY_data, aes(x = YearMonth, y = Avg_Temperature, group = 1)) +
  geom_line(color = "grey", size = 1) +  # Blue line for temperature trend
  geom_smooth(method = "lm", color = "red", linetype = "dashed", size = 1) +  # Trend line
  labs(title = "Temperature Changes Over Time (New York)",
       x = "Year-Month",
       y = "Average Temperature (°C)") +
  theme_minimal() +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y")  # Show labels every 5 years
