# Olist E-Commerce Analitika Layihəsi

## 1. Layihə haqqında qısa
Bu layihədə Olist e-ticarət məlumatlarından istifadə edərək end-to-end bir KPI və analitika çərçivəsi qurdum. Məqsədim xam məlumatları təmizləyib SQL-də analiz etmək, sonda isə Python vasitəsilə vizual qrafiklərə çevirərək real biznes insaytları əldə etmək idi.
---
## 2. Verilənlər Bazası və `v_order_analytics` View-u
* Hər dəfə cədvəlləri birləşdirməmək üçün mərkəzi bir VIEW yaratdım:
* Yalnız uğurla çatdırılmış sifarişləri götürdüm (delivered)
* Sifariş içindəki məhsullara görə rəqəmlərin iki dəfə hesablanmaması üçün GROUP BY order_id məntiqindən istifadə etdim.
---
## 3. Yazdığım Əsas və Bonus SQL Sorğuları
Layihədə aşağıdakı əsas və bonus göstəriciləri hesabladım:
* AOV (orta sifariş dəyəri), ümumi gəlir, çatdırılma müddətləri və rəy balları.
* Sifarişlərin neçə faizinin vaxtında və ya vaxtından əvvəl çatdığını tapdım.
* Heç rəy yazılmamış sifarişləri müəyyən edib ümumi payını hesabladım.
* Hər kateqoriya üzrə daşıma xərcinin məhsul qiymətinə nisbətinə baxdım. Daşıma xərci 15%-i keçən kateqoriyaları High Freight Erosion olaraq işarələdim.
* Hər kateqoriyanın aylıq ümumi gəlirdə neçə faiz payı olduğunu və zamanla necə dəyişdiyini izlədim.
---
## 4. Python-da Vizuallaşdırma
SQL-dən çıxardığım nəticələri Python-a (pandas, matplotlib, seaborn) ötürərək bu qrafikləri düzəltdim:
1. **Aylıq gəlir trendi:** Zaman üzrə gəlirin necə dəyişdiyini göstərən xətt qrafiki.
2. **Top kateqoriyalar:** Ən çox pul qazandıran kateqoriyaları göstərən bar chart.
3. **Çatdırılma vs Rəy balı:** Gecikmələrin müştəri məmnuniyyətinə necə təsir etdiyini göstərən səpələnmə qrafiki (scatter plot).
---
## 5. Nəticədə Çıxardığım 5 Biznes İnsaytı

1. **Gecikən kateqoriyalara nəzarət etməliyik:** Çatdırılma müddəti uzandıqca müştəri rəy balları kəskin düşür. Gecikməsi çox olan satıcılara xəbərdarlıq edilməlidir.
2. **Daşıma xərci:** Bəzi kateqoriyalarda daşıma xərci qiymətin 15%-indən çoxdur. Ya həmin məhsulların qiyməti artırılmalı, ya da daşıma şirkəti ilə endirim danışığı aparılmalıdır.
3. **Rəy yazılmasını təşviq etməliyik:** Çatdırılan sifarişlərin xeyli hissəsi rəysiz qalır. Müştərilərə növbəti alışda endirim təklif etməklə rəy sayını artırmaq olar.
4. **Mövsümi büdcə bölgüsü:** Kateqoriyaların aylıq gəlir payları dəyişir. Reklam xərclərini il boyu eyni cür deyil, hansı ay hansı kateqoriya populyardırsa, ona uyğun xərcləməliyik.
5. **Zəif kateqoriyaları təmizləməliyiq:** Ən az qazanc gətirən aşağı səviyyəli kateqoriyalar anbar yükü yaradır. Onları ya daraltmaq, ya da tamamilə ləğv edib diqqəti ən çox satan top kateqoriyalara yönəltmək lazımdır.
