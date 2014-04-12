setwd("~/Websites/Soccer/R\ Scripts")
games <- read.csv("game_diffs.csv", header=T)
names(games) <- c("id", "sh", "sg", "g", "a", "of", "fd", "fc", "sv", "yc", "rc")

# Single variable analysis
# Goals
summary(games$g)
hist(games$g, main="Goal Diff Distribution", xlab="Home goals - away goals")

# Shots
summary(games$sh)
table(games$sh)
hist(games$sh, main="Shots Diff Distribution", xlab="Home shots - Away shots", breaks=40)

# Shots on goal
summary(games$sg)
table(games$sg)
hist(games$sg, main="Shots on Goal Diff Distribution", xlab="Home shots on goal - Away shots on goal", breaks=20)

# Assists
summary(games$a)
table(games$a)
hist(games$a, main="Assists Diff Distribution", xlab="Assists (home - away)")

# Multivariable analysis
plot(games$g, games$sg)
fit <- lm(g ~ sh + sg + a + of + fd + fc + sv + yc + rc, data=games)
summary(fit)

# Offsides, fouls drawn, fouls committed, yellow cards are insignificant
# Shots and shots on goal are highly correlated
fit <- lm(g ~ sg + sv + a + rc, data=games)
summary(fit)

# Create win column (loss = -1, tie = 0, win = 1)
games$win <- games$g / abs(games$g)
games['win'] <- rapply( games['win'], f=function(x) ifelse(is.nan(x),0,x), how="replace" )

# Multivariable analysis (ind var of win)
win.model <- lm(win ~ sh + sg + a + of + fd + fc + sv + yc + rc, data=games)
summary(win.model)


