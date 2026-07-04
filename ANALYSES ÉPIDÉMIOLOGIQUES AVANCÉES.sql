/***************************************************************************************************
* ANALYSES ÉPIDÉMIOLOGIQUES AVANCÉES
* PostgreSQL 12+
***************************************************************************************************/


/***************************************************************************************************
36. TAUX D'ATTAQUE PAR PROVINCE
***************************************************************************************************/

SELECT
    province,
    COUNT(*) AS cas,
    population,
    ROUND((COUNT(*)::NUMERIC / population) * 100, 2) AS taux_attaque
FROM CasEpidemie c
JOIN Population p USING (province)
GROUP BY province, population
ORDER BY taux_attaque DESC;


/***************************************************************************************************
37. TAUX DE LÉTALITÉ PAR MALADIE
***************************************************************************************************/

SELECT
    maladie,
    COUNT(*) FILTER (WHERE statut='Décédé') AS deces,
    COUNT(*) AS cas,
    ROUND(
        COUNT(*) FILTER (WHERE statut='Décédé')::NUMERIC
        *100/COUNT(*),2
    ) AS taux_letalite
FROM CasEpidemie
GROUP BY maladie
ORDER BY taux_letalite DESC;


/***************************************************************************************************
38. CAS PAR TRANCHE D'ÂGE ET SEXE
***************************************************************************************************/

SELECT
    sexe,
    CASE
        WHEN age < 5 THEN '0-4'
        WHEN age < 15 THEN '5-14'
        WHEN age < 25 THEN '15-24'
        WHEN age < 45 THEN '25-44'
        WHEN age < 65 THEN '45-64'
        ELSE '65+'
    END tranche_age,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY sexe, tranche_age
ORDER BY sexe, tranche_age;


/***************************************************************************************************
39. NOMBRE DE CAS PAR JOUR DE LA SEMAINE
***************************************************************************************************/

SELECT
    TO_CHAR(date_confirmation,'Day') jour,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY jour
ORDER BY cas DESC;


/***************************************************************************************************
40. DISTRICTS SANS NOUVEAUX CAS DEPUIS 30 JOURS
***************************************************************************************************/

SELECT
    district,
    MAX(date_confirmation) derniere_detection
FROM CasEpidemie
GROUP BY district
HAVING MAX(date_confirmation) < CURRENT_DATE - INTERVAL '30 days';


/***************************************************************************************************
41. DÉTECTION D'UNE AUGMENTATION BRUTALE
***************************************************************************************************/

WITH semaine AS
(
    SELECT
        DATE_TRUNC('week',date_confirmation) periode,
        COUNT(*) cas
    FROM CasEpidemie
    GROUP BY periode
)
SELECT
    periode,
    cas,
    LAG(cas) OVER(ORDER BY periode) ancienne_valeur,
    ROUND(
        ((cas -
        LAG(cas) OVER(ORDER BY periode))::NUMERIC
        /
        NULLIF(LAG(cas) OVER(ORDER BY periode),0))
        *100,2
    ) variation_pct
FROM semaine;


/***************************************************************************************************
42. DÉLAI MOYEN DE DÉCLARATION
***************************************************************************************************/

SELECT
    ROUND(
        AVG(date_confirmation - date_symptomes),
        2
    ) AS delai_moyen
FROM CasEpidemie;


/***************************************************************************************************
43. TOP DES CENTRES DE SANTÉ DÉCLARANTS
***************************************************************************************************/

SELECT
    centre_sante,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY centre_sante
ORDER BY cas DESC
LIMIT 20;


/***************************************************************************************************
44. MALADIES LES PLUS FRÉQUENTES CHEZ LES ENFANTS
***************************************************************************************************/

SELECT
    maladie,
    COUNT(*) cas
FROM CasEpidemie
WHERE age < 18
GROUP BY maladie
ORDER BY cas DESC;


/***************************************************************************************************
45. MALADIES LES PLUS FRÉQUENTES CHEZ LES PERSONNES ÂGÉES
***************************************************************************************************/

SELECT
    maladie,
    COUNT(*) cas
FROM CasEpidemie
WHERE age >= 60
GROUP BY maladie
ORDER BY cas DESC;


/***************************************************************************************************
46. ANALYSE DES RÉINFECTIONS
***************************************************************************************************/

SELECT
    patient_id,
    COUNT(*) nombre_infections
FROM CasEpidemie
GROUP BY patient_id
HAVING COUNT(*) > 1;


/***************************************************************************************************
47. SURVEILLANCE DES DÉCÈS PAR MOIS
***************************************************************************************************/

SELECT
    DATE_TRUNC('month',date_confirmation) mois,
    COUNT(*) FILTER (WHERE statut='Décédé') deces
FROM CasEpidemie
GROUP BY mois
ORDER BY mois;


/***************************************************************************************************
48. TAUX DE SURVIE PAR MALADIE
***************************************************************************************************/

SELECT
    maladie,
    ROUND(
        COUNT(*) FILTER (WHERE statut<>'Décédé')::NUMERIC
        *100/COUNT(*),2
    ) taux_survie
FROM CasEpidemie
GROUP BY maladie;


/***************************************************************************************************
49. ANALYSE DES CAS IMPORTÉS
***************************************************************************************************/

SELECT
    pays_origine,
    COUNT(*) cas
FROM CasEpidemie
WHERE origine_contamination='Importé'
GROUP BY pays_origine
ORDER BY cas DESC;


/***************************************************************************************************
50. DENSITÉ DE CAS PAR KM²
***************************************************************************************************/

SELECT
    province,
    COUNT(*) cas,
    superficie_km2,
    ROUND(
        COUNT(*)::NUMERIC/superficie_km2,
        2
    ) densite
FROM CasEpidemie c
JOIN Provinces p USING(province)
GROUP BY province, superficie_km2;


/***************************************************************************************************
51. DÉTECTION DES SUPER PROPAGATEURS
***************************************************************************************************/

SELECT
    patient_id,
    nombre_contacts
FROM CasEpidemie
WHERE nombre_contacts >= 20
ORDER BY nombre_contacts DESC;


/***************************************************************************************************
52. CAS PAR PROFESSION
***************************************************************************************************/

SELECT
    profession,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY profession
ORDER BY cas DESC;


/***************************************************************************************************
53. ANALYSE DES FEMMES ENCEINTES INFECTÉES
***************************************************************************************************/

SELECT
    COUNT(*) AS femmes_enceintes
FROM CasEpidemie
WHERE enceinte = TRUE;


/***************************************************************************************************
54. TAUX DE VACCINATION DES CAS
***************************************************************************************************/

SELECT
    statut_vaccinal,
    COUNT(*) patients
FROM CasEpidemie
GROUP BY statut_vaccinal;


/***************************************************************************************************
55. EFFICACITÉ APPARENTE DE LA VACCINATION
***************************************************************************************************/

SELECT
    statut_vaccinal,
    COUNT(*) FILTER (WHERE statut='Décédé') deces,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY statut_vaccinal;


/***************************************************************************************************
56. ANALYSE DES CAS PAR HEURE
***************************************************************************************************/

SELECT
    EXTRACT(HOUR FROM date_enregistrement) heure,
    COUNT(*) cas
FROM CasEpidemie
GROUP BY heure
ORDER BY heure;


/***************************************************************************************************
57. TEMPS MOYEN ENTRE ADMISSION ET DÉCÈS
***************************************************************************************************/

SELECT
    ROUND(
        AVG(date_deces - date_admission),
        2
    ) jours
FROM CasEpidemie
WHERE date_deces IS NOT NULL;


/***************************************************************************************************
58. SURVEILLANCE DES MALADIES ZOONOTIQUES
***************************************************************************************************/

SELECT
    maladie,
    espece_animale,
    COUNT(*) cas
FROM CasEpidemie
WHERE espece_animale IS NOT NULL
GROUP BY maladie, espece_animale;


/***************************************************************************************************
59. SCORE DE RISQUE PAR PATIENT
***************************************************************************************************/

SELECT
    patient_id,
    age,
    nombre_comorbidites,
    CASE
        WHEN age >= 65 AND nombre_comorbidites >= 2 THEN 'Très élevé'
        WHEN age >= 50 THEN 'Élevé'
        WHEN age >= 30 THEN 'Moyen'
        ELSE 'Faible'
    END score_risque
FROM CasEpidemie;


/***************************************************************************************************
60. TABLEAU DE BORD ÉPIDÉMIOLOGIQUE EXÉCUTIF
***************************************************************************************************/

SELECT
    COUNT(*) total_cas,
    COUNT(*) FILTER (WHERE statut='Actif') actifs,
    COUNT(*) FILTER (WHERE statut='Guéri') gueris,
    COUNT(*) FILTER (WHERE statut='Décédé') deces,
    COUNT(DISTINCT province) provinces_affectees,
    COUNT(DISTINCT district) districts_affectes,
    COUNT(DISTINCT maladie) maladies_surveillees,
    ROUND(AVG(age),2) age_moyen
FROM CasEpidemie;