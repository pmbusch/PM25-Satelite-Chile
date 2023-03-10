## Analysis on PM25 Population exposure
## PBH
## February 2023

library(tidyverse)
theme_set(theme_bw(16)+ 
            theme(panel.grid.major = element_blank(),
                  axis.title.y=element_text(angle=0,margin=margin(r=-70))))


# load data 
pm25_exp <- read.delim("Data/pm25exposure.csv",sep=";")

pm25_exp_region <- pm25_exp %>% 
  mutate(codigo_region=as.factor(codigo_region)) %>% 
  mutate(pop_pm25=poblacion*pm25_Exposure) %>% 
  group_by(codigo_region,year,month) %>% 
  summarise(pop_pm25=sum(pop_pm25,na.rm=T),
            total_pop=sum(poblacion,na.rm = T)) %>% 
  # summarise(pm25_exposure=stats::weighted.mean(pm25_Exposure,poblacion,na.rm=T,)) %>% 
  ungroup() %>% 
  mutate(pm25_exposure=pop_pm25/total_pop)

pm25_exp_commune <- pm25_exp %>% 
  mutate(codigo_comuna=as.factor(codigo_comuna)) %>% 
  mutate(pop_pm25=poblacion*pm25_Exposure) %>% 
  group_by(codigo_comuna,year,month) %>% 
  summarise(pop_pm25=sum(pop_pm25,na.rm=T),
            total_pop=sum(poblacion,na.rm = T)) %>% 
  # summarise(pm25_exposure=stats::weighted.mean(pm25_Exposure,poblacion,na.rm=T,)) %>% 
  ungroup() %>% 
  mutate(pm25_exposure=pop_pm25/total_pop)

## table ------

table <- pm25_exp_region %>% group_by(codigo_region) %>% 
  summarise(Mean=mean(pm25_exposure),
            `S.D.`=sd(pm25_exposure),
            Min=min(pm25_exposure),
            Median=median(pm25_exposure),
            Max=max(pm25_exposure)) %>% 
  rename(Region=codigo_region)

total_table <- pm25_exp_region %>% 
  summarise(Mean=mean(pm25_exposure),
            `S.D.`=sd(pm25_exposure),
            Min=min(pm25_exposure),
            Median=median(pm25_exposure),
            Max=max(pm25_exposure))
total_table$Region <- "Total"
table <- rbind(table,total_table)

flextable(table) %>% 
  autofit() %>% 
  colformat_double(j=2:6,digits=1) %>% 
  bold(i=17) %>% hline(i=16)



# figure density ---

pm25_exp_dens <- pm25_exp %>% 
  mutate(pop_pm25=poblacion*pm25_Exposure) %>% 
  mutate(season=case_when(
    month>3 & month<7 ~ "Fall",
    month>3 & month < 10 ~ "Winter",
    month>3 & month <13 ~ "Spring",
    T ~ "Summer") %>% factor(levels=c("Fall","Spring","Winter","Summer"))) %>% 
  group_by(codigo_comuna,season) %>% 
  summarise(pop_pm25=sum(pop_pm25,na.rm=T),
            total_pop=sum(poblacion,na.rm = T)) %>% 
  ungroup() %>% 
  mutate(pm25_exposure=pop_pm25/total_pop)
pm25_exp_dens$pop_pm25 <- NULL; pm25_exp_dens$total_pop <- NULL

pop_commune <- pm25_exp %>% group_by(codigo_comuna,geocodigo) %>% 
  summarise(pop=mean(poblacion,na.rm=T)) %>% ungroup() %>% 
  group_by(codigo_comuna) %>% 
  summarise(pop=sum(pop,na.rm=T))
pop_commune$pop %>% sum()
pm25_exp_dens <- pm25_exp_dens %>% left_join(pop_commune)  

# % district zones
library(chilemapas)
zonas_2017 <- censo_2017_zonas %>% group_by(geocodigo) %>% 
  summarise(poblacion=sum(poblacion))
mapa_zona <-chilemapas::mapa_zonas %>% left_join(zonas_2017) 
sum(mapa_zona$poblacion,na.rm=T)/sum(censo_2017_comunas$poblacion)


pm25_exp_dens %>% 
  ggplot(aes(pm25_exposure))+
  geom_histogram(aes( y = ..density.., weight = pop), fill="brown",bins=50)+
  facet_wrap(~season)+
  geom_vline(xintercept = 12, linetype="dashed")+
  annotate("text", x = 11, y = 0.15, angle = 90,label = "WHO Guideline")+
  labs(x="PM2.5 Exposure [ug/m3]",y="")+
  coord_cartesian(expand = F)+
  theme(legend.position = "none")


# figure time series ------
pm25_exp_region %>% 
  mutate(date=as.Date(paste(year,month,"01",sep="-"),"%Y-%m-%d")) %>% 
  ggplot(aes(date,pm25_exposure,
                           col=codigo_region,group=codigo_region))+
  geom_line()+
  labs(x="",y="PM2.5 Exposure",col="Region")+
  theme_bw()

pm25_exp_commune %>% 
  mutate(date=as.Date(paste(year,month,"01",sep="-"),"%Y-%m-%d")) %>% 
  ggplot(aes(date,pm25_exposure,group=codigo_comuna))+
  geom_line(alpha=.5,size=.5)+
  coord_cartesian(expand = F)+
  labs(x="",y="PM2.5 Exposure [ug/m3]")+
  scale_x_date(date_breaks = "6 month",date_labels = "%Y-%b")+
  theme(axis.title.y=element_text(angle=0,margin=margin(r=-145)))

pm25_exp_commune$codigo_comuna %>% unique() %>% length()

# EoF