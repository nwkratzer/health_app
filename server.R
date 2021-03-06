df<-read.csv("all cities health ineq.csv",header=TRUE)
library(shiny)
library(dichromat)
library(magrittr)
library(ggplot2)
library(classInt)
library(ggthemes)

rank_and_nb_group<-function(df, var, order="Descending"){
  df<-df
  df$var <- var
  if(order=="Descending"){
    d.order<-df[order(-df$var),]
  }
  if(order=="Ascending"){
    d.order<-df[order(df$var),]
  }
  ranks<-1:length(df$var)
  d.rank<-cbind(d.order,ranks)
  names<-paste(d.rank$ranks,".",sep="")
  names<-paste(names,d.rank$cz_name.x)
  d.graph<-cbind(d.rank,names)
  
  breaks<-classIntervals(d.graph$var,3,style="jenks")
  d.graph$color<-NA
  d.graph$color[d.graph$var<=breaks$brks[2]]<-"green"
  d.graph$color[d.graph$var>breaks$brks[2] & d.graph$var<=breaks$brks[3]]<-"yellow"
  d.graph$color[d.graph$var>breaks$brks[3]]<-"red"
  d.graph$round<-format(round(d.graph$var,1),nsmall=1)
  d.graph$textfont<-"plain"
  d.graph$textfont[d.graph$cz_name.x=="Louisville"]<-"bold"
  d.graph$linecolor<-"white"
  d.graph$linecolor[d.graph$cz_name.x=="Louisville"]<-"black"
  d.graph
  
  p<-ggplot(data=d.graph,aes(x=factor(names, levels=rev(unique(names))),
                        y=var*100,fill=factor(color)))+guides(fill=FALSE)
  p<-p+geom_bar(stat="identity",color=rev(d.graph$linecolor))+coord_flip()+theme_tufte()
  if(order=="Ascending"){
    p<-p+scale_fill_manual(values=c("green3","red2","yellow2"))
  }
  if(order=="Descending"){
    p<-p+scale_fill_manual(values=c("red2","green3","yellow2"))
  }
  p<-p+theme(axis.text.y=element_text(hjust=0,face=rev(d.graph$textfont),
                                      size=12))
  p<-p+theme(axis.ticks=element_blank(),axis.text.x=element_blank())
  p<-p+geom_text(aes(label=round),hjust=1.1,size=5,fontface="bold")
  p<-p+labs(title="",x="",
            y="")
  p
}

##converting variables to the correct units
df$cur_smoke_q1<-df$cur_smoke_q1*100
df$bmi_obese_q1<-df$bmi_obese_q1*100
df$exercise_any_q1<-df$exercise_any_q1*100


shinyServer(
  function(input, output) {
    var1 <- reactive({
      switch(input$var1, 
             "Female Life Expectancy, Low Income" = df$le_agg_q1_F,
             "Male Life Expectancy, Low Income" = df$le_agg_q1_M,
             "Smoking, Low Income"=df$cur_smoke_q1,
             "Obesity Rate, Low Income"=df$bmi_obese_q1,
             "Exercise in last 30 days, Low Income"=df$exercise_any_q1)
    })
    var2 <- reactive({
      switch(input$var2, 
             "Female Life Expectancy, Low Income" = df$le_agg_q1_F,
             "Male Life Expectancy, Low Income" = df$le_agg_q1_M,
             "Smoking, Low Income"=df$cur_smoke_q1,
             "Obesity Rate, Low Income"=df$bmi_obese_q1,
             "Exercise in last 30 days, Low Income"=df$exercise_any_q1)
    })
    order_one <- reactive({
      if(input$var1=="Male Life Expectancy, Low Income"|
         input$var1=="Female Life Expectancy, Low Income"|
         input$var1=="Exercise in last 30 days, Low Income"){
        order<-"Descending"
      }
      if(input$var1=="Obesity Rate, Low Income"|
         input$var1=="Smoking, Low Income"){
        order<-"Ascending"
      }
      order
    })
    order_two <- reactive({
      if(input$var2=="Male Life Expectancy, Low Income"|
         input$var2=="Female Life Expectancy, Low Income"|
         input$var2=="Exercise in last 30 days, Low Income"){
        order<-"Descending"
      }
      if(input$var2=="Obesity Rate, Low Income"|
         input$var2=="Smoking, Low Income"){
        order<-"Ascending"
      }
      order
    })
    
    output$plot1 <- renderPlot({ 
      df$var1 <- var1()
      df$var2 <- var2()
      if(input$peer_list=="Current"){
        df<-subset(df, Current == 1)
      }
      if(input$peer_list=="Baseline"){
        df<-subset(df, Baseline ==1)
      }
      df$textfont<-"plain"
      df$textfont[df$Display=="LOU"]<-"bold"
      df$textcolor<-"black"
      df$textcolor[df$Display=="LOU"]<-"blue"
      p<-ggplot(df, aes(x=var2,y=var1))
      p<-p+geom_smooth(method="lm",se=FALSE, color="black", size=.5)
      p<-p+geom_text(aes(label=Display),fontface=df$textfont, color=df$textcolor)
      p<-p+labs(title="",x=input$var2,
                y=input$var1)
      p<-p+theme_bw()
      p
    })
    output$plot2<-renderPlot({
      df$var1 <- var1()
      if(input$peer_list=="Current"){
        df<-subset(df, Current == 1)
      }
      if(input$peer_list=="Baseline"){
        df<-subset(df, Baseline ==1)
      }
      p2<-rank_and_nb_group(df, df$var1, order=order_one())
      p2
  })
    output$plot3<-renderPlot({
      df$var2 <- var2()
      if(input$peer_list=="Current"){
        df<-subset(df, Current == 1)
      }
      if(input$peer_list=="Baseline"){
        df<-subset(df, Baseline ==1)
      }
      p3<-rank_and_nb_group(df, df$var2, order=order_two())
      p3
    })
    output$text1<-renderText({
      if(input$peer_list=="Current"){
        output_text<-"Current Peer Cities: BIR = Birmingham, CHA = Charlotte, CIN = Cincinatti, COL = Columbus, GBR = Greensboro, GR = Grand Rapids, GVL = Greensville, IND = Indianapolis, KC = Kansas City, KNO = Knoxville, LOU = Louisville, MEM = Memphis, NAS = Nashville, OKL = Oklahoma, OMA = Omaha, STL= St. Louis, TUL = Tulsa"
      }
      if(input$peer_list=="Baseline"){
        output_text<-"Baseline Peer Cities: BIR = Birmingham, CHA = Charlotte, CIN = Cincinatti, COL = Columbus, DAY = Dayton, GBR = Greensboro, IND = Indianapolis, JAC = Jacksonville, KC = Kansas City, LOU = Louisville, MEM = Memphis, NAS = Nashville, OKL = Oklahoma, OMA = Omaha, RAL = Raleigh, RIC = Richmond"
      }
      output_text
    })
    output$text2<-renderText({
      if(input$var1=="Female Life Expectancy, Low Income"){
        output_text<-"Life expectancy at age 40 for women in the bottom quartile of the income distribution."
      }
      if(input$var1=="Male Life Expectancy, Low Income"){
        output_text<-"Life expectancy at age 40 for men in the bottom quartile of the income distribution."
      }
      if(input$var1=="Smoking, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who smoke."
      }
      if(input$var1=="Obesity Rate, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who are obese."
      }
      if(input$var1=="Exercise in last 30 days, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who have exercised in the last 30 days."
      }
      output_text
    })
    
    output$text3<-renderText({
      if(input$var2=="Female Life Expectancy, Low Income"){
        output_text<-"Life expectancy at age 40 for women in the bottom quartile of the income distribution."
      }
      if(input$var2=="Male Life Expectancy, Low Income"){
        output_text<-"Life expectancy at age 40 for men in the bottom quartile of the income distribution."
      }
      if(input$var2=="Smoking, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who smoke."
      }
      if(input$var2=="Obesity Rate, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who are obese."
      }
      if(input$var2=="Exercise in last 30 days, Low Income"){
        output_text<-"Percent of population in the bottom quartile of the income distribution who have exercised in the last 30 days."
      }
      output_text
    })
    
    output$textvar1<-renderText({input$var1})
    output$textvar2<-renderText({input$var2})
})    