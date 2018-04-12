#!/usr/bin/Rscript --vanilla

suppressPackageStartupMessages(library(ggplot2))

call_with_file <- function(file, mode, func) {
  con <- file(description=file, open=mode)
  ret <- func(con)
  close(con)
  return(ret)
}

d <- call_with_file('stdin', 'r', function(con) {
  num <- c()
  cli <- c()
  while (length(l <- readLines(con, n=1, warn=F)) > 0) {
    num[length(num) + 1] = sub('^ *([[:digit:]]+) .+', '\\1', l)
    cli[length(cli) + 1] = sub('^ *[[:digit:]]+ (.+) http.+', '\\1', l)
  }
  return(data.frame(id=1:length(num), num=as.numeric(num), cli=cli))
})
pdf('plot_cli.pdf')
g <- ggplot(d, aes(x=reorder(x=cli, X=rev(id)), y=num))
old = theme_set(theme_gray(base_family="Japan1"))
print(g + geom_bar(stat="identity", position='dodge', aes(fill=cli))
        + coord_flip()
        + labs(x="client's name", y='# of clients')
        + guides(fill=F))
graphics.off()
