library("ggplot2")
# library("httpgd")
library("dplyr")
# hgd()

data <- read.csv("traindata.csv")
data <- data %>% filter(
    ObsID == 15683401000028390467953640
    | ObsID == 15684401000021586816725080
    | ObsID == 15684401000022385204540140
)
data$ObsID <- factor(data$ObsID,
                     levels = c(15684401000022385204540140,
                                15684401000021586816725080,
                                15683401000028390467953640))
data$ArrTime <- as.POSIXct(strptime(data$ArrTime, format = "%H:%M:%S"))
data$StopName <- factor(data$StopName,
    levels = unique(
        data$StopName[
            with(data, order(ObsID, ArrTime))
        ]
    )
)
ggplot(data = data, aes(x = ArrTime, y = StopName, color = ObsID, group = 1)) +
    scale_x_datetime(date_label = "%H:%M") +
    geom_point() +
    geom_line()

dat1 <- data.frame(
    sex = factor(c("Female","Female","Male","Male")),
    time = factor(c("Lunch","Dinner","Lunch","Dinner"), levels=c("Lunch","Dinner")),
    total_bill = c(13.53, 16.81, 16.24, 17.42)
)

ggplot(data=dat1, aes(x=time, y=total_bill, group=sex, color=sex)) +
    geom_line() +
    geom_point()
