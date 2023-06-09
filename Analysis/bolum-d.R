# Çözümleme-D
# Bir OxN ve NxO tablosu için Satır Etki ve Sütun Etki modellerinin çözümlemelerini yapınız.

df <- read.csv("../Datasets/processed.csv")
head(df,3)

## NxO Satır Etki Modeli Çözümlemesi

# Satır: Sex (Erkek, Kadın) \
# Sütun: Likert 4 (Kız/Erkek arkadaşım ben olmadan gece eğlenmeye çıkabilir.) \
# 
# |Ölçek|Anlamı|
#   |:----|:-----|
#   |1|Kesinlikle katılmıyorum|
#   |2|Katılmıyorum|
#   |3|Ne katılıyorum ne de katılmıyorum|
#   |4|Katılıyorum|
#   |5|Kesinlikle katılıyorum|
#   
#   
tablo <- xtabs(~ Sex + likert_4, data = df)

df_tablo <- as.data.frame.table(tablo)

yeni_tablo <- data.frame(Sex = df_tablo$Sex,
                         Ölçek = df_tablo$likert_4,
                         Frekansı = df_tablo$Freq)

yeni_tablo$Sex <- as.factor(yeni_tablo$Sex)

yeni_tablo$Ölçek <- factor(yeni_tablo$Ölçek,
                           labels=c("Kesinlikle Katılmıyorum",
                                    "Katılmıyorum",
                                    "Ne Katılıyorum Ne Katılmıyorum",
                                    "Katılıyorum",
                                    "Kesinlikle Katılıyorum"))

likertSkor <- as.numeric(yeni_tablo$Ölçek)
yeni_tablo

options(contrasts=c("contr.sum","contr.poly"))

# **Not:** \
# 
# - Kontrast kodlaması, bir faktör değişkenin kategorik seviyeleri arasındaki farkları ifade etmek için kullanılan bir yöntemdir. contr.sum kontrastı, kategoriler arasındaki farkları toplam olarak ifade ederken, contr.poly kontrastı ise polinomik bir eğilimi yansıtır.
# 
# - Örneğin, bir faktör değişkenin 3 kategorisi varsa, contr.sum kodlamasıyla bir kategori referans alınır ve diğer kategoriler bu referans kategoriye göre farklar olarak temsil edilir. contr.poly kodlaması ise kategoriler arasında bir polinomik eğilimi ifade etmek için kullanılır.

model <- glm(Frekansı ~ Ölçek + Sex*likertSkor,
             data = yeni_tablo, 
             family = poisson)

#install.packages("vcdExtra")
library(vcdExtra)
LRstats(model)

# 
# $H_0:$ Satır etki modeline uyum vardır.  
# $H_1:$ Satır etki modeline uyum yoktur
# 
# p-değeri=0.4106, $\alpha=0.05$'ten büyük olduğu için yokluk hipotezi reddedilemez. %95 Güvenle söylenebilir ki satır etki modeline uyum vardır.
# 
# **Not:**\
# Satır modeline uyum olduğu için, beklenen sıklıklar üzerinden satır düzeyindeki yerel odds oranları birbirine eşittir

summary(model)

# Satır etki modeline göre $\hat{\mu_1}$ katsayısı -0.21083 olarak tahmin edilmiştir. Buradan hareketle $\hat{\mu_2}=0-(-0.21083)=0.21083$ olarak bulunmuş oldu. Satır etkileri için;
# 
# $H_0: \mu_i = 0$
# $H_1: \mu_i \neq 0$
# 
# p-value=0.013781 < $\alpha=0.05$'ten küçük olduğu için yokluk hipotezi reddedilir. Satır etkisi %5 hata payıyla istatistiksel olarak anlamlıdır.

### Beklenen Sıklıkların Hesaplanması:
matrix(fitted(model), byrow = T, ncol = 5,
       dimnames = list(
         Sex=c("Erkek", "Kadın"),
         Ölçek=c("K. Katılmıyorum",
                 "Katılmıyorum",
                 "Nötrüm",
                 "Katılıyorum",
                 "K. Katılıyorum")
       ))

### Odds Oranlarının Hesaplanması
mu1 <- coef(model)["Sex1:likertSkor"];mu1
mu2 <- 0 - (mu1);mu2

teta11 <- exp(mu2-mu1);teta11

# $$\theta_{11} = e^{\hat{\mu_2} - \hat{\mu_1}} \approx 1.52$$
#   **Yorum:** \
# - "Kız/Erkek arkadaşım ben olmadan gece eğlenmeye çıkabilir" önergesine katılma durumunun j. düzeyde olanların (𝑗+1). düzeyde olmasına göre, cinsiyetin kadın olmasının erkek olmasına göre bu önergeye katılma olasılığını 1,52 kat arttırmaktadır.


## OxN Sütun Etki Modeli Çözümlemesi
# Satıra ordinal bir değişken olarak, görüşülen gün sayısını 3 guruba balyaladım.
# 
# Sütun: Soru13: Kız / Erkek arkadaşınızla bir ayda yaklaşık kaç gün görüşüyorsunuz?
#   Satır: Department

df$GörüşülenGün <- cut(df$soru13,
                       breaks = c(0, 10, 20, 30),
                       labels = c("Düşük", "Orta", "Yüksek"),
                       right = FALSE)
head(df)

tablo <- xtabs(~ GörüşülenGün + soru8, data = df)

df_tablo <- as.data.frame.table(tablo)

df_tablo$GörüşülenGün <- as.factor(df_tablo$GörüşülenGün)
df_tablo$soru8 <- as.factor(df_tablo$soru8)

library(dplyr)
df_tablo$soru8 <- recode(df_tablo$soru8,
                         "Kişinin fiziksel özellikleri (boy, kilo, saç rengi vb.)"="Fizik",
                         "Kişinin karakteri ve kişilik özellikleri"="Karakter",
                         "Kişinin maddi ve ekonomik durumu"="Maddiyat")

GSkor <- as.numeric(df_tablo$GörüşülenGün)
df_tablo

model <- glm(Freq ~ GörüşülenGün + soru8*GSkor,
             data = df_tablo,
             family = poisson)

library(vcdExtra)
LRstats(model)

# 
# $H_0:$ Kurulan sütun etki modele uyum vardır.  
# $H_1:$ Kurulan sütun etki modele uyum yoktur.  

# p-value=0.1944 değeri $\alpha=0.05$'ten büyük olduğu için yokluk hipotezi reddedilemez. Sütun etki modeline uyum vardır şeklinde bir yorum %5 hata ile yapılabilir.

summary(model)

# Satır etki modeline göre $\hat{\tau_1}$ katsayısı 0.2898, $\hat{\tau_2}$ katsayısı 0.4864 olarak tahmin edilmiştir. Buradan hareketle $\hat{\tau_3}=0-(0.2898+0.4864) = -0.7762$ olarak bulunmuş oldu. sütun etkileri için;
# 
# $H_0: \tau_i = 0$
# $H_1: \tau_i \neq 0$

# p-value > $\alpha=0.05$'ten küçük olduğu için yokluk hipotezi reddedilemez. Sütun etkileri istatistiksel olarak anlamlı bulunmamıştır.

### Odds Oranları

maddiyatSkor<- 0-(coef(model)["soru81:GSkor"]+coef(model)["soru82:GSkor"])

theta11 <- exp(coef(model)["soru82:GSkor"]-coef(model)["soru81:GSkor"]);theta11

theta12 <- exp(maddiyatSkor-coef(model)["soru82:GSkor"]);theta12

theta13 <- exp(maddiyatSkor-coef(model)["soru81:GSkor"]);theta13


# $$\theta_{11} = e^{\hat{\tau_2} - \hat{\tau_1}} \approx 1.22$$
#   $$\theta_{12} = e^{\hat{\tau_3} - \hat{\tau_2}} \approx 0.28$$
#   $$\theta_{13} = e^{\hat{\tau_3} - \hat{\tau_1}} \approx 0.34$$
#   
#   **Yorumlar:**  
#   
#   - "Kız/Erkek arkadaşı seçiminde hangi faktör sizin için en önemlisidir?" sorusuna verilen yanıtlar bakımından "Fizik" yanıtını verenlerin "Karakter" yanıtını verenlere göre Kız/Erkek arkadaşıyla ayda görüştüğü gün sayısının (i+1). düzeyde olmasına göre i. düzeyde olması olasılığı 1.22 kat fazladır.
# 
# - Kız/Erkek arkadaşıyla ayda görüştüğü gün sayısının (i+1). düzeyde olmasına göre i. düzeyde olanların,"Kız/Erkek arkadaşı seçiminde hangi faktör sizin için en önemlisidir?" sorusuna verdikleri yanıtlar bakımından "Maddiyat" yanıtını vermesi "Karakter" yanıtını vermesine göre ($1/0.28=3.57$) kat fazladır.

- Kız/Erkek arkadaşıyla ayda görüştüğü gün sayısının (i+1). düzeyde olmasına göre i. düzeyde olanların,"Kız/Erkek arkadaşı seçiminde hangi faktör sizin için en önemlisidir?" sorusuna verdikleri yanıtlar bakımından "Maddiyat" yanıtını verenlerin "Fizik" yanıtını verenlere göre ($1/0.34=2.94$) kat fazladır.