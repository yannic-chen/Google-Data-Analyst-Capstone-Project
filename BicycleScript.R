library(lubridate)
library(ggplot2)
library(tidyverse)

# loading data --------------------------------------------------------------------

#combining all csv data files into a large dataframe. 
#Thit dataframe should have 3742202 rows
fulldata <- rbind(
  read.csv(file = "Bicycle Data/Original/202005-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202006-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202007-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202008-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202009-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202010-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202011-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202012-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202101-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202102-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202103-divvy-tripdata.csv"),
  read.csv(file = "Bicycle Data/Original/202104-divvy-tripdata.csv")
)

# processing data ------------------------------------------------------------------

fulldata$ended_at <- strptime(fulldata$ended_at, "%Y-%m-%d %H:%M:%OS")
fulldata$started_at <- strptime(fulldata$started_at, "%Y-%m-%d %H:%M:%OS")
fulldata$ride_length <- as.numeric(fulldata$ended_at - fulldata$started_at)
#fulldata$ride_length <- difftime(fulldata$ended_at, fulldata$started_at, units="secs")
#fulldata$ride_length_time <- sprintf('%02d:%02d:%02d', seconds_to_period(fulldata$ride_length)@hour, minute(seconds_to_period(fulldata$ride_length)), second(seconds_to_period(fulldata$ride_length)))

Sys.setlocale("LC_TIME", "C") #change locale language to "C", which will be english. Also avoids error message: "OS reports request to set locale to "en_US" cannot be honored".
fulldata$day_of_week <- weekdays(as.Date(fulldata$started_at))

#remove datapoints where the ridelength is 0 or less.Remaining: 3731285 rows
fulldata <- fulldata[fulldata$ride_length > 0,]
#remove NA. Remaining 3731171
fulldata <- fulldata[!is.na(fulldata$ride_length),]
#remove datapoints where the ridelength is more than 86400 (1 day). Remaining 3728161
fulldata <- fulldata[fulldata$ride_length < 86400,]
#data only for rides less than 8 hours. Remaining 3722751
eightdata <- fulldata[fulldata$ride_length < 28800,]
#data only for rides less than 1 hours. Remaining 3722751
onehourdata <- fulldata[fulldata$ride_length < 3600,]

memberdata <- fulldata %>% filter(member_casual == "member")
casualdata <- fulldata %>% filter(member_casual == "casual")

# analyzing data -------------------------------------------------------------------

summary(fulldata)

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
Mode(fulldata$day_of_week)

# statistics-------------------------------------------------------------------
summary(seconds_to_period(fulldata$ride_length))

# Compare members and casual users
aggregate(fulldata$ride_length ~ fulldata$member_casual, FUN = mean)
aggregate(fulldata$ride_length ~ fulldata$member_casual, FUN = median)

# See the average ride time by each day for members vs casual users
aggregate(fulldata$ride_length ~ fulldata$member_casual + fulldata$day_of_week, FUN = mean)

# analyze ridership data by type and weekday
fulldata %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>%  #creates weekday field using wday()
  group_by(member_casual, weekday) %>%  #groups by usertype and weekday
  summarise(number_of_rides = n()							#calculates the number of rides and average duration 
            ,average_duration = mean(ride_length)) %>% 		# calculates the average duration
  arrange(member_casual, weekday)							# sorts


## Effect of weekday on bicycle usage  -------------------------------------------------------------------
day_order <- c('Monday', 'Tuesday', 'Wednesday', "Thursday", "Friday", "Saturday", "Sunday")
ggplot(data = fulldata) + 
  geom_bar(mapping = aes(x = factor(day_of_week, level = day_order), fill = rideable_type)) + 
  facet_wrap(~member_casual) +
  labs(title = "casual vs member bicycle e-sharing", x = "day of the week") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

# Let's visualize the number of rides by rider type
fulldata %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge")


## Customer type based on ride-length  -------------------------------------------------------------------
# Let's create a visualization for average duration
fulldata %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n() ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")



#24-hour
summary(cut(fulldata$ride_length, breaks=20)) #unordered factor
fulldata$bins <- cut(fulldata$ride_length,breaks = 20)

ggplot(data = fulldata) + 
  geom_bar(mapping = aes(x = bins, fill = member_casual)) +
  labs(title = "riding length by count (24-hour)", x = "riding length (min)") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_x_discrete(labels=as.character(seq(0,1440,72)[4:21]), limits = c("(8.64e+03,1.3e+04]",  "(1.3e+04,1.73e+04]", 
                                                                         "(1.73e+04,2.16e+04]", "(2.16e+04,2.59e+04]", "(2.59e+04,3.02e+04]", "(3.02e+04,3.46e+04]",
                                                                         "(3.46e+04,3.89e+04]", "(3.89e+04,4.32e+04]", "(4.32e+04,4.75e+04]", "(4.75e+04,5.18e+04]",
                                                                         "(5.18e+04,5.62e+04]", "(5.62e+04,6.05e+04]", "(6.05e+04,6.48e+04]", "(6.48e+04,6.91e+04]",
                                                                         "(6.91e+04,7.34e+04]", "(7.34e+04,7.78e+04]", "(7.78e+04,8.21e+04]", "(8.21e+04,8.65e+04]"))

#8-hour
summary(cut(eightdata$ride_length, breaks=20))
eightdata$bins <- cut(eightdata$ride_length,breaks = 20)

ggplot(data = eightdata) + 
  geom_bar(mapping = aes(x = bins, fill = member_casual)) +
  labs(title = "riding length by count (8-hour)", x = "riding length (min)") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_x_discrete(labels=as.character(seq(0,480,24)[2:21])) +
  ylim(0,200000)

#1-hour
summary(cut(onehourdata$ride_length, breaks=20))
onehourdata$bins <- cut(onehourdata$ride_length,breaks = 20)

ggplot(data = onehourdata) + 
  geom_bar(mapping = aes(x = bins, fill = member_casual)) +
  labs(title = "riding length by count (1-hour)", x = "riding length (min)") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_x_discrete(labels=c("3", "6", "9", "12", "15", "18", "21", "24", "27", "30", "33", "36", "39", "42", "45", "48", "51", "54", "57", "60"))

# stations -------------------------------------------------------------------------------

ssid_data <- fulldata[!is.na(fulldata$start_station_id),] #removes NA
ssid_data <- ssid_data[ssid_data$start_station_id != "",] #removes other "empty" columns
#drop rows with low occurence
count(ssid_data, 'start_station_id')
tab <- table(ssid_data$start_station_id)

ggplot(data = ssid_data[ssid_data$start_station_id %in% names(tab)[tab>1000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(start_station_id), fill = member_casual), stat = 'count')

ggplot(data = ssid_data[ssid_data$start_station_id %in% names(tab)[tab>10000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(start_station_id), fill = member_casual), stat = 'count') + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  labs(title = "popularity of starting station", x = "station id")

ggplot(data = ssid_data[ssid_data$start_station_id %in% names(tab)[tab>10000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(start_station_id), fill = member_casual), stat = 'count') + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 4)) +
  labs(title = "popularity of starting station", x = "station id") +
  facet_wrap(~factor(day_of_week, levels = day_order))


esid_data <- fulldata[!is.na(fulldata$end_station_id),] #removes NA
esid_data <- esid_data[esid_data$end_station_id != "",] #removes other "empty" columns
#drop rows with low occurence
count(esid_data, 'end_station_id')
tab <- table(esid_data$end_station_id)

ggplot(data = esid_data[esid_data$end_station_id %in% names(tab)[tab>1000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(end_station_id), fill = member_casual), stat = 'count')

ggplot(data = esid_data[esid_data$end_station_id %in% names(tab)[tab>10000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(end_station_id), fill = member_casual), stat = 'count') + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  labs(title = "popular final destination", x = "station id")

ggplot(data = esid_data[esid_data$end_station_id %in% names(tab)[tab>10000],]) + 
  geom_bar(mapping = aes(x = forcats::fct_infreq(end_station_id), fill = member_casual), stat = 'count') + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 4)) +
  labs(title = "popular final destination", x = "station id") + 
  facet_wrap(~factor(day_of_week, levels = day_order))

#starting time of rides---------------------------------------------------------------------------
start_data <- fulldata
start_data$start_hour <- as.numeric(format(strptime(fulldata$started_at,"%Y-%m-%d %H:%M:%OS"),'%H'))


ggplot(data = start_data) + 
  geom_bar(mapping = aes(x = start_hour, fill = member_casual), stat = 'count') + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  labs(title = "bike usage by starting hour", x = "starting hour") + 
  facet_wrap(~factor(day_of_week, levels = day_order))


#export data --------------------------
counts <- aggregate(fulldata$ride_length ~ fulldata$member_casual + fulldata$day_of_week, FUN = mean)
write.csv(counts, file = 'E:\\Study\\Google Data analyst\\Course 8 - Capstone\\avg_ride_length.csv')
