SELECT "Free Meal Count (K-12)" / "Enrollment (K-12)" AS "Free Meal Count (K-12) / Enrollment (K-12)" FROM frpm WHERE "County Name" = 'Alameda' ORDER BY "Free Meal Count (K-12)" / "Enrollment (K-12)" DESC LIMIT 1	california_schools
SELECT CAST("Free Meal Count (Ages 5-17)" AS REAL) / CAST("Enrollment (Ages 5-17)" AS REAL) AS "Free Meal Count (Ages 5-17) / Enrollment (Ages 5-17)" FROM frpm WHERE "Educational Option Type" = 'Continuation School' AND "Free Meal Count (Ages 5-17)" IS NOT NULL AND "Enrollment (Ages 5-17)" IS NOT NULL AND "Enrollment (Ages 5-17)" > 0 ORDER BY CAST("Free Meal Count (Ages 5-17)" AS REAL) / CAST("Enrollment (Ages 5-17)" AS REAL) ASC LIMIT 3	california_schools
SELECT s.Zip FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 AND f."District Name" = 'Fresno County Office of Education'	california_schools
SELECT s.MailStreet FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) ORDER BY f."FRPM Count (K-12)" DESC LIMIT 1	california_schools
SELECT s.Phone FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 AND f."Charter Funding Type" = 'Directly funded' AND s.OpenDate > '2000-01-01'	california_schools
SELECT COUNT(DISTINCT T2.School) FROM satscores AS T1 INNER JOIN schools AS T2 ON T1.cds = T2.CDSCode WHERE T2.Virtual = 'F' AND T1.AvgScrMath > 400	california_schools
SELECT s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE sat.NumTstTakr > 500 AND s.Magnet = 1	california_schools
SELECT s.Phone FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY sat.NumGE1500 DESC LIMIT 1	california_schools
SELECT s.NumTstTakr FROM frpm f JOIN satscores s ON CAST(f.CDSCode AS INTEGER) = CAST(s.cds AS INTEGER) ORDER BY f."FRPM Count (K-12)" DESC LIMIT 1	california_schools
SELECT COUNT(T2.`School Code`) FROM satscores AS T1 JOIN frpm AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T1.AvgScrMath > 560 AND T2.`Charter Funding Type` = 'Directly funded'	california_schools
SELECT "FRPM Count (Ages 5-17)" FROM satscores JOIN frpm ON CAST(satscores.cds AS INTEGER) = CAST(frpm.CDSCode AS INTEGER) ORDER BY satscores.AvgScrRead DESC LIMIT 1	california_schools
SELECT "CDSCode" FROM frpm WHERE ("Enrollment (K-12)" + "Enrollment (Ages 5-17)") > 500	california_schools
SELECT MAX(CAST(T1.`Free Meal Count (Ages 5-17)` AS REAL) / T1.`Enrollment (Ages 5-17)`) FROM frpm AS T1 JOIN satscores AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.cds AS INTEGER) WHERE CAST(T2.NumGE1500 AS REAL) / T2.NumTstTakr > 0.3	california_schools
SELECT s.Phone FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE sat.NumTstTakr > 0 ORDER BY CAST(sat.NumGE1500 AS REAL) / sat.NumTstTakr DESC LIMIT 3	california_schools
SELECT s.NCESSchool FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY f."Enrollment (Ages 5-17)" DESC LIMIT 5	california_schools
SELECT s.dname AS District FROM satscores s JOIN schools sch ON s.cds = sch.CDSCode WHERE s.rtype = 'D' AND sch.StatusType = 'Active' ORDER BY s.AvgScrRead DESC LIMIT 1	california_schools
SELECT COUNT(T1.CDSCode) FROM schools AS T1 INNER JOIN satscores AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.cds AS INTEGER) WHERE T1.County = 'Alameda' AND T1.StatusType = 'Merged' AND T2.NumTstTakr < 100	california_schools
SELECT s."CharterNum", sat."AvgScrWrite", ROW_NUMBER() OVER (ORDER BY sat."AvgScrWrite" DESC) AS "WritingScoreRank" FROM schools s JOIN satscores sat ON CAST(s."CDSCode" AS INTEGER) = CAST(sat."cds" AS INTEGER) WHERE sat."AvgScrWrite" > 499 AND s."CharterNum" IS NOT NULL ORDER BY sat."AvgScrWrite" DESC	california_schools
SELECT COUNT(T1.CDSCode) FROM schools AS T1 INNER JOIN satscores AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.cds AS INTEGER) WHERE T1.County = 'Fresno' AND T1.FundingType = 'Directly funded' AND T2.NumTstTakr <= 250	california_schools
SELECT s.Phone FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrMath DESC LIMIT 1	california_schools
SELECT COUNT(T1.`School Name`) FROM frpm AS T1 WHERE T1.`County Name` = 'Amador' AND T1.`Low Grade` = '9' AND T1.`High Grade` = '12'	california_schools
SELECT COUNT(frpm.CDSCode) FROM frpm JOIN schools ON CAST(frpm.CDSCode AS INTEGER) = CAST(schools.CDSCode AS INTEGER) WHERE schools.County = 'Los Angeles' AND frpm."Free Meal Count (K-12)" > 500 AND frpm."FRPM Count (K-12)" < 700	california_schools
SELECT sname FROM satscores WHERE cname = 'Contra Costa' ORDER BY NumTstTakr DESC LIMIT 1	california_schools
SELECT s.School, s.Street FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE (f."Enrollment (K-12)" - f."Enrollment (Ages 5-17)") > 30	california_schools
SELECT frpm."School Name" FROM frpm JOIN satscores ON CAST(frpm."CDSCode" AS INTEGER) = CAST(satscores.cds AS INTEGER) WHERE (frpm."Free Meal Count (K-12)" / frpm."Enrollment (K-12)") > 0.1 AND satscores.NumGE1500 >= 1500	california_schools
SELECT s.sname, f."Charter Funding Type" FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) JOIN frpm f ON CAST(sch.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE sch.City = 'Riverside' AND s.AvgScrMath > 400	california_schools
SELECT f."School Name", s.Street, s.City, s.State, s.Zip FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."County Name" = 'Monterey' AND f."School Type" = 'High Schools (Public)' AND f."FRPM Count (Ages 5-17)" > 800	california_schools
SELECT s.School, sat.AvgScrWrite, s.Phone FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE STRFTIME('%Y', s.OpenDate) > '1991' OR (s.ClosedDate IS NOT NULL AND STRFTIME('%Y', s.ClosedDate) < '2000')	california_schools
WITH avg_diff AS ( SELECT AVG(CAST("Enrollment (K-12)" AS REAL) - CAST("Enrollment (Ages 5-17)" AS REAL)) AS avg_difference FROM frpm WHERE "Charter Funding Type" = 'Locally funded' ) SELECT s.School, s.DOCType AS DOC FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) CROSS JOIN avg_diff WHERE f."Charter Funding Type" = 'Locally funded' AND (CAST(f."Enrollment (K-12)" AS REAL) - CAST(f."Enrollment (Ages 5-17)" AS REAL)) > avg_diff.avg_difference	california_schools
SELECT s.OpenDate FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.GSoffered = 'K-12' ORDER BY f."Enrollment (K-12)" DESC LIMIT 1	california_schools
SELECT DISTINCT s.City FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE f."Enrollment (K-12)" IS NOT NULL ORDER BY f."Enrollment (K-12)" ASC LIMIT 5	california_schools
SELECT CAST(`Free Meal Count (K-12)` AS REAL) / `Enrollment (K-12)` FROM frpm ORDER BY `Enrollment (K-12)` DESC LIMIT 2 OFFSET 9	california_schools
SELECT CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)` FROM frpm AS T1 JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode WHERE T2.SOC = '66' ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5	california_schools
SELECT s.Website, s.School AS "School Name" FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Free Meal Count (Ages 5-17)" BETWEEN 1900 AND 2000	california_schools
SELECT CAST(T2.`Free Meal Count (Ages 5-17)` AS REAL) / T2.`Enrollment (Ages 5-17)` FROM schools AS T1 JOIN frpm AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T1.AdmFName1 = 'Kacey' AND T1.AdmLName1 = 'Gibson'	california_schools
SELECT s.AdmEmail1 FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 ORDER BY f."Enrollment (K-12)" ASC LIMIT 1	california_schools
SELECT s.AdmFName1, s.AdmLName1, s.AdmFName2, s.AdmLName2, s.AdmFName3, s.AdmLName3 FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY sat.NumGE1500 DESC LIMIT 1	california_schools
SELECT s.Street, s.City, s.State, s.Zip FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE sat.NumTstTakr > 0 AND sat.NumTstTakr IS NOT NULL ORDER BY CAST(sat.NumGE1500 AS REAL) / sat.NumTstTakr ASC LIMIT 1	california_schools
SELECT s.Website FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE s.County = 'Los Angeles' AND sat.NumTstTakr BETWEEN 2000 AND 3000	california_schools
SELECT AVG(T1.NumTstTakr) FROM satscores AS T1 INNER JOIN schools AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.County = 'Fresno' AND STRFTIME('%Y', T2.OpenDate) = '1980'	california_schools
SELECT s.Phone FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE sat.dname = 'Fresno Unified' ORDER BY sat.AvgScrRead ASC LIMIT 1	california_schools
SELECT "School" FROM ( SELECT s."School", ROW_NUMBER() OVER (PARTITION BY s."County" ORDER BY sat."AvgScrRead" DESC) as rn FROM schools s JOIN satscores sat ON CAST(s."CDSCode" AS INTEGER) = CAST(sat."cds" AS INTEGER) WHERE s."Virtual" = 'F' ) WHERE rn <= 5	california_schools
SELECT s.EdOpsName FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrMath DESC LIMIT 1	california_schools
SELECT s.AvgScrMath, sch.County FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE s.AvgScrMath IS NOT NULL AND s.AvgScrRead IS NOT NULL AND s.AvgScrWrite IS NOT NULL ORDER BY (s.AvgScrMath + s.AvgScrRead + s.AvgScrWrite) ASC LIMIT 1	california_schools
SELECT s.AvgScrWrite, sch.City FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) ORDER BY s.NumGE1500 DESC LIMIT 1	california_schools
SELECT s.School, sat.AvgScrWrite FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE s.AdmFName1 = 'Ricci' AND s.AdmLName1 = 'Ulrich'	california_schools
SELECT s.School FROM schools s JOIN frpm f ON s.CDSCode = f.CDSCode WHERE s.DOC = '31' ORDER BY f."Enrollment (K-12)" DESC LIMIT 1	california_schools
SELECT CAST(COUNT(School) AS REAL) / 12 FROM schools WHERE County = 'Alameda' AND DOC = '52' AND STRFTIME('%Y', OpenDate) = '1980'	california_schools
SELECT CAST(SUM(CASE WHEN DOC = '54' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN DOC = '52' THEN 1 ELSE 0 END) FROM schools WHERE County = 'Orange' AND StatusType = 'Merged'	california_schools
WITH closed_schools AS ( SELECT County, School, ClosedDate FROM schools WHERE StatusType = 'Closed' ), county_counts AS ( SELECT County, COUNT(*) as school_count FROM closed_schools GROUP BY County ), top_county AS ( SELECT County FROM county_counts ORDER BY school_count DESC LIMIT 1 ) SELECT cs.County, cs.School, cs.ClosedDate FROM closed_schools cs JOIN top_county tc ON cs.County = tc.County ORDER BY cs.School	california_schools
SELECT s.MailStreet, COALESCE(s.School, sat.sname) AS School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrMath DESC LIMIT 1 OFFSET 6	california_schools
SELECT s.MailStreet, s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrRead ASC LIMIT 1	california_schools
SELECT COUNT(T1.cds) FROM satscores AS T1 JOIN schools AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.MailCity = 'Lakeport' AND (T1.AvgScrRead + T1.AvgScrMath + T1.AvgScrWrite) >= 1500	california_schools
SELECT s.NumTstTakr FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE sch.MailCity = 'Fresno'	california_schools
SELECT School, MailZip FROM schools WHERE (AdmFName1 = 'Avetik' AND AdmLName1 = 'Atoian') OR (AdmFName2 = 'Avetik' AND AdmLName2 = 'Atoian')	california_schools
SELECT CAST(SUM(CASE WHEN County = 'Colusa' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN County = 'Humboldt' THEN 1 ELSE 0 END) FROM schools WHERE MailState = 'CA'	california_schools
SELECT COUNT(CDSCode) FROM schools WHERE MailState = 'CA' AND City = 'San Joaquin' AND StatusType = 'Active'	california_schools
SELECT s.Phone, s.Ext FROM schools s JOIN satscores sat ON s.CDSCode = sat.cds ORDER BY sat.AvgScrWrite DESC LIMIT 1 OFFSET 332	california_schools
SELECT Phone, Ext, School FROM schools WHERE Zip = '95203-3704'	california_schools
SELECT Website FROM schools WHERE (AdmFName1 = 'Mike' AND AdmLName1 = 'Larson') OR (AdmFName2 = 'Mike' AND AdmLName2 = 'Larson') OR (AdmFName3 = 'Mike' AND AdmLName3 = 'Larson') OR (AdmFName1 = 'Dante' AND AdmLName1 = 'Alvarez') OR (AdmFName2 = 'Dante' AND AdmLName2 = 'Alvarez') OR (AdmFName3 = 'Dante' AND AdmLName3 = 'Alvarez')	california_schools
SELECT Website FROM schools WHERE Virtual = 'P' AND Charter = 1 AND County = 'San Joaquin'	california_schools
SELECT COUNT(School) FROM schools WHERE Charter = 1 AND City = 'Hickman' AND DOC = '52'	california_schools
SELECT COUNT(T2.School) FROM frpm AS T1 JOIN schools AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.County = 'Los Angeles' AND T2.Charter = 0 AND (T1."Free Meal Count (K-12)" * 100.0 / T1."Enrollment (K-12)") < 0.18	california_schools
SELECT AdmFName1, AdmLName1, School, City FROM schools WHERE Charter = 1 AND CharterNum = '00D2'	california_schools
SELECT COUNT(*) FROM schools WHERE MailCity = 'Hickman' AND CharterNum = '00D4'	california_schools
SELECT CAST(SUM(CASE WHEN FundingType = 'Locally funded' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN FundingType != 'Locally funded' THEN 1 ELSE 0 END) FROM schools WHERE County = 'Santa Clara'	california_schools
SELECT COUNT(School) FROM schools WHERE County = 'Stanislaus' AND FundingType = 'Directly funded' AND OpenDate BETWEEN '2000-01-01' AND '2005-12-31'	california_schools
SELECT COUNT(School) FROM schools WHERE City = 'San Francisco' AND DOCType = 'Community College District' AND STRFTIME('%Y', ClosedDate) = '1989'	california_schools
SELECT County FROM schools WHERE SOC = '11' AND ClosedDate IS NOT NULL AND strftime('%Y', ClosedDate) BETWEEN '1980' AND '1989' GROUP BY County ORDER BY COUNT(*) DESC LIMIT 1	california_schools
SELECT NCESDist FROM schools WHERE SOC = '31'	california_schools
SELECT COUNT(School) FROM schools WHERE County = 'Alpine' AND EdOpsName = 'District Community Day School' AND StatusType IN ('Active', 'Closed')	california_schools
SELECT DISTINCT frpm."District Code" FROM schools JOIN frpm ON CAST(schools.CDSCode AS INTEGER) = CAST(frpm.CDSCode AS INTEGER) WHERE schools.City = 'Fresno' AND schools.Magnet = 0	california_schools
SELECT "frpm"."Enrollment (Ages 5-17)" FROM schools JOIN frpm ON CAST(schools.CDSCode AS INTEGER) = CAST(frpm.CDSCode AS INTEGER) WHERE schools.City = 'Fremont' AND schools.EdOpsCode = 'SSS' AND frpm."Academic Year" = '2014-2015'	california_schools
SELECT frpm."FRPM Count (Ages 5-17)" FROM schools JOIN frpm ON CAST(schools.CDSCode AS INTEGER) = CAST(frpm.CDSCode AS INTEGER) WHERE frpm."Educational Option Type" = 'Youth Authority School' AND schools.MailStreet = 'PO Box 1040'	california_schools
SELECT MIN(T1.`Low Grade`) FROM frpm AS T1 JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode WHERE T2.EdOpsCode = 'SPECON' AND T2.NCESDist = '0613360'	california_schools
SELECT schools.EILName, schools.School FROM frpm JOIN schools ON frpm.CDSCode = schools.CDSCode WHERE frpm."NSLP Provision Status" = 'Breakfast Provision 2' AND frpm."County Code" = '37'	california_schools
SELECT s.City FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."NSLP Provision Status" = 'Lunch Provision 2' AND f."Low Grade" = '9' AND CAST(f."High Grade" AS INTEGER) = 12 AND f."County Name" = 'Merced' AND s.EILCode = 'HS'	california_schools
SELECT s."School", f.`FRPM Count (Ages 5-17)` * 100.0 / f.`Enrollment (Ages 5-17)` FROM schools s JOIN frpm f ON CAST(s."CDSCode" AS INTEGER) = CAST(f."CDSCode" AS INTEGER) WHERE s."County" = 'Los Angeles' AND s."GSserved" = 'K-9'	california_schools
SELECT GSserved FROM schools WHERE City = 'Adelanto' GROUP BY GSserved ORDER BY COUNT(*) DESC LIMIT 1	california_schools
SELECT County, COUNT(Virtual) FROM schools WHERE County IN ('San Diego', 'Santa Barbara') AND Virtual = 'F' GROUP BY County	california_schools
SELECT EILName AS "School Type", School AS "School Name", Latitude FROM schools ORDER BY Latitude DESC LIMIT 1	california_schools
SELECT s.City, f."Low Grade", s.School AS "School Name" FROM schools s JOIN frpm f ON s.CDSCode = f.CDSCode WHERE s.State = 'CA' ORDER BY s.Latitude ASC LIMIT 1	california_schools
SELECT GSoffered FROM schools ORDER BY ABS(Longitude) DESC LIMIT 1	california_schools
SELECT T1.City, COUNT(T2.CDSCode) FROM schools T1 JOIN frpm T2 ON T1.CDSCode = T2.CDSCode WHERE T1.Magnet = 1 AND T1.GSoffered = 'K-8' AND T2."NSLP Provision Status" = 'Multiple Provision Types' GROUP BY T1.City	california_schools
SELECT AdmFName1, District FROM schools WHERE AdmFName1 IS NOT NULL GROUP BY AdmFName1, District ORDER BY COUNT(*) DESC LIMIT 2	california_schools
SELECT CAST("frpm"."Free Meal Count (K-12)" AS REAL) * 100 / "frpm"."Enrollment (K-12)" AS "Free Meal Count (K-12) * 100 / Enrollment (K-12)", "frpm"."District Code" FROM schools JOIN frpm ON schools."CDSCode" = frpm."CDSCode" WHERE schools."AdmFName1" = 'Alusine'	california_schools
SELECT AdmLName1, District, County, School FROM schools WHERE CharterNum = '0040'	california_schools
SELECT AdmEmail1, AdmEmail2 FROM schools WHERE County = 'San Bernardino' AND District = 'San Bernardino City Unified' AND OpenDate BETWEEN '2009-01-01' AND '2010-12-31' AND SOC = '62' AND DOC = '54'	california_schools
SELECT s.AdmEmail1, s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.NumGE1500 DESC LIMIT 1	california_schools
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A3 = 'east Bohemia' AND T2.frequency = 'POPLATEK PO OBRATU'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A3 = 'Prague'	financial
SELECT IIF(AVG(A13) > AVG(A12), '1996', '1995') FROM district	financial
SELECT COUNT(DISTINCT T2.district_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'F' AND T2.A11 BETWEEN 6000 AND 10000	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'M' AND T2.A3 = 'north Bohemia' AND T2.A11 > 8000	financial
SELECT a.account_id, (SELECT MAX(A11) - MIN(A11) FROM district) AS gap FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN district dist ON a.district_id = dist.district_id WHERE c.gender = 'F' ORDER BY c.birth_date ASC, dist.A11 ASC LIMIT 1	financial
SELECT d.account_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN district dist ON c.district_id = dist.district_id ORDER BY c.birth_date DESC, CAST(dist.A11 AS REAL) DESC LIMIT 1	financial
SELECT COUNT(T1.account_id) FROM account AS T1 JOIN disp AS T2 ON T1.account_id = T2.account_id WHERE T1.frequency = 'POPLATEK TYDNE' AND T2.type = 'OWNER'	financial
SELECT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id WHERE d.type = 'DISPONENT' AND a.frequency = 'POPLATEK PO OBRATU'	financial
SELECT a.account_id FROM loan l JOIN account a ON l.account_id = a.account_id WHERE l.status = 'A' AND STRFTIME('%Y', l.date) = '1997' AND a.frequency = 'POPLATEK TYDNE' AND l.amount = ( SELECT MIN(l2.amount) FROM loan l2 JOIN account a2 ON l2.account_id = a2.account_id WHERE l2.status = 'A' AND STRFTIME('%Y', l2.date) = '1997' AND a2.frequency = 'POPLATEK TYDNE' )	financial
SELECT a.account_id FROM account a JOIN loan l ON a.account_id = l.account_id WHERE l.duration > 12 AND STRFTIME('%Y', a.date) = '1993' ORDER BY l.amount DESC LIMIT 1	financial
SELECT COUNT(T2.client_id) FROM district AS T1 INNER JOIN account AS T4 ON T1.district_id = T4.district_id INNER JOIN disp AS T3 ON T4.account_id = T3.account_id INNER JOIN client AS T2 ON T3.client_id = T2.client_id WHERE T2.gender = 'F' AND T2.birth_date < '1950-01-01' AND T1.A2 = 'Sokolov'	financial
SELECT DISTINCT account_id FROM trans WHERE STRFTIME('%Y', date) = '1995' AND date = (SELECT MIN(date) FROM trans WHERE STRFTIME('%Y', date) = '1995')	financial
SELECT DISTINCT a.account_id FROM account a JOIN ( SELECT account_id, balance FROM trans t1 WHERE t1.trans_id = ( SELECT MAX(t2.trans_id) FROM trans t2 WHERE t2.account_id = t1.account_id ) ) t ON a.account_id = t.account_id WHERE a.date < '1997-01-01' AND t.balance > 3000 ORDER BY a.account_id	financial
SELECT d.client_id FROM card c JOIN disp d ON c.disp_id = d.disp_id WHERE c.issued = '1994-03-03'	financial
SELECT a.date FROM trans t JOIN account a ON t.account_id = a.account_id WHERE t.amount = 840 AND t.date = '1998-10-14'	financial
SELECT a.district_id FROM loan l JOIN account a ON l.account_id = a.account_id WHERE l.date = '1994-08-25'	financial
SELECT MAX(t.amount) AS amount FROM card c JOIN disp d ON c.disp_id = d.disp_id JOIN account a ON d.account_id = a.account_id JOIN trans t ON a.account_id = t.account_id WHERE c.issued = '1996-10-21'	financial
SELECT c.gender FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN district dist ON a.district_id = dist.district_id WHERE dist.A11 = (SELECT MAX(CAST(A11 AS INTEGER)) FROM district) ORDER BY c.birth_date ASC LIMIT 1	financial
SELECT t.amount FROM loan l JOIN account a ON l.account_id = a.account_id JOIN trans t ON a.account_id = t.account_id WHERE l.amount = (SELECT MAX(amount) FROM loan) AND t.date > a.date ORDER BY t.date LIMIT 1	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN account AS T3 ON T2.account_id = T3.account_id JOIN district AS T4 ON T3.district_id = T4.district_id WHERE T4.A2 = 'Jesenik' AND T1.gender = 'F'	financial
SELECT d.disp_id FROM trans t JOIN disp d ON t.account_id = d.account_id WHERE t.amount = 5100 AND t.date = '1998-09-02'	financial
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A2 = 'Litomerice' AND STRFTIME('%Y', T2.date) = '1996'	financial
SELECT d.A2 FROM client c JOIN disp di ON c.client_id = di.client_id JOIN account a ON di.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE c.gender = 'F' AND c.birth_date = '1976-01-29'	financial
SELECT c.birth_date FROM loan l JOIN account a ON l.account_id = a.account_id JOIN disp d ON a.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE l.amount = 98832 AND l.date = '1996-01-03'	financial
SELECT account.account_id FROM client JOIN disp ON client.client_id = disp.client_id JOIN account ON disp.account_id = account.account_id JOIN district ON account.district_id = district.district_id WHERE district.A3 = 'Prague' ORDER BY account.date ASC LIMIT 1	financial
SELECT CAST(SUM(T1.gender = 'M') AS REAL) * 100 / COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A3 = 'south Bohemia' AND CAST(T2.A4 AS INTEGER) = ( SELECT MAX(CAST(A4 AS INTEGER)) FROM district WHERE A3 = 'south Bohemia' )	financial
SELECT CAST((SUM(IIF(T3.date = '1998-12-27', T3.balance, 0)) - SUM(IIF(T3.date = '1993-03-22', T3.balance, 0))) AS REAL) * 100 / SUM(IIF(T3.date = '1993-03-22', T3.balance, 0)) FROM trans T3 WHERE T3.account_id = ( SELECT T1.account_id FROM loan T1 WHERE T1.date = '1993-07-05' AND T1.status = 'B' ORDER BY T1.loan_id LIMIT 1 ) AND T3.date IN ('1993-03-22', '1998-12-27')	financial
SELECT (CAST(SUM(CASE WHEN status = 'A' THEN amount ELSE 0 END) AS REAL) * 100) / SUM(amount) FROM loan	financial
SELECT CAST(SUM(status = 'C') AS REAL) * 100 / COUNT(account_id) FROM loan WHERE amount < 100000	financial
SELECT a.account_id, d.A2, d.A3 FROM account a JOIN district d ON a.district_id = d.district_id WHERE a.frequency = 'POPLATEK PO OBRATU' AND STRFTIME('%Y', a.date) = '1993'	financial
SELECT account.account_id, account.frequency FROM account JOIN district ON account.district_id = district.district_id WHERE STRFTIME('%Y', account.date) BETWEEN '1995' AND '2000' AND district.A3 = 'east Bohemia'	financial
SELECT account.account_id, account.date FROM account JOIN district ON account.district_id = district.district_id WHERE district.A2 = 'Prachatice'	financial
SELECT d.A2, d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.loan_id = 4990	financial
SELECT a.account_id, d.A2, d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.amount > 300000	financial
SELECT l.loan_id, d.A2, d.A11 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.duration = 60	financial
SELECT CAST((T3.A13 - T3.A12) AS REAL) * 100 / T3.A12 FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id JOIN district AS T3 ON T2.district_id = T3.district_id WHERE T1.status = 'D'	financial
SELECT CAST(SUM(T1.A2 = 'Decin') AS REAL) * 100 / COUNT(account_id) FROM account AS T2 JOIN district AS T1 ON T2.district_id = T1.district_id WHERE STRFTIME('%Y', T2.date) = '1993'	financial
SELECT account_id FROM account WHERE frequency = 'POPLATEK MESICNE'	financial
SELECT d.A2, COUNT(c.client_id) FROM client c JOIN disp di ON c.client_id = di.client_id JOIN district d ON c.district_id = d.district_id WHERE c.gender = 'F' GROUP BY d.A2 ORDER BY COUNT(c.client_id) DESC LIMIT 9	financial
SELECT d.A2 FROM trans t JOIN account a ON t.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE t.type = 'VYDAJ' AND t.date LIKE '1996-01%' AND t.operation != 'VYBER KARTOU' ORDER BY t.amount DESC LIMIT 10	financial
SELECT COUNT(T3.account_id) FROM account AS T3 JOIN district AS T4 ON T3.district_id = T4.district_id LEFT JOIN disp AS T5 ON T3.account_id = T5.account_id LEFT JOIN card AS T6 ON T5.disp_id = T6.disp_id WHERE T4.A3 = 'south Bohemia' AND T6.card_id IS NULL	financial
SELECT d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.status IN ('C', 'D') GROUP BY d.A3 ORDER BY SUM(l.amount) DESC LIMIT 1	financial
SELECT AVG(T4.amount) FROM loan AS T4 JOIN account AS T3 ON T4.account_id = T3.account_id JOIN disp AS T2 ON T3.account_id = T2.account_id JOIN client AS T1 ON T2.client_id = T1.client_id WHERE T1.gender = 'M'	financial
SELECT district_id, A2 FROM district WHERE A13 = (SELECT MAX(A13) FROM district)	financial
SELECT COUNT(T2.account_id) FROM district AS T1 JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A16 = (SELECT MAX(CAST(A16 AS INTEGER)) FROM district)	financial
SELECT COUNT(T1.account_id) FROM trans AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.operation = 'VYBER KARTOU' AND T2.frequency = 'POPLATEK MESICNE' AND T1.balance < 0	financial
SELECT COUNT(T1.account_id) FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.date BETWEEN '1995-01-01' AND '1997-12-31' AND T1.amount >= 250000 AND T2.frequency = 'POPLATEK MESICNE' AND T1.status = 'A'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN loan AS T2 ON T1.account_id = T2.account_id WHERE T1.district_id = 1 AND T2.status IN ('C', 'D')	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A15 = ( SELECT A15 FROM district ORDER BY CAST(A15 AS INTEGER) DESC LIMIT 1 OFFSET 1 ) AND T1.gender = 'M'	financial
SELECT COUNT(T1.card_id) FROM card AS T1 JOIN disp AS T2 ON T1.disp_id = T2.disp_id WHERE T1.type = 'gold' AND T2.type = 'OWNER'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A2 = 'Pisek'	financial
SELECT DISTINCT a.district_id FROM trans t JOIN account a ON t.account_id = a.account_id WHERE STRFTIME('%Y', t.date) = '1997' AND t.amount > 10000	financial
SELECT DISTINCT a.account_id FROM account a JOIN "order" o ON a.account_id = o.account_id WHERE a.district_id = 18 AND o.k_symbol = 'SIPO'	financial
SELECT a.account_id FROM account a JOIN disp d ON a.account_id = d.account_id JOIN card c ON d.disp_id = c.disp_id WHERE c.type = 'gold'	financial
SELECT AVG(T4.amount) FROM trans AS T4 WHERE T4.operation = 'VYBER KARTOU' AND STRFTIME('%Y', T4.date) = '1998'	financial
SELECT DISTINCT account_id FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) = '1998' AND amount < ( SELECT AVG(amount) FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) = '1998' )	financial
SELECT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN card cd ON d.disp_id = cd.disp_id JOIN loan l ON d.account_id = l.account_id WHERE c.gender = 'F'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'F' AND T2.A3 = 'south Bohemia'	financial
SELECT account.account_id FROM account JOIN district ON account.district_id = district.district_id JOIN disp ON account.account_id = disp.account_id WHERE district.A2 = 'Tabor' AND disp.type = 'OWNER'	financial
SELECT DISTINCT disp.type FROM disp JOIN account ON disp.account_id = account.account_id JOIN district ON account.district_id = district.district_id WHERE disp.type != 'OWNER' AND district.A11 > 8000 AND district.A11 <= 9000	financial
SELECT COUNT(T2.account_id) FROM trans AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id JOIN district AS T3 ON T2.district_id = T3.district_id WHERE T3.A3 = 'north Bohemia' AND T1.bank = 'AB'	financial
SELECT DISTINCT d.A2 FROM trans t JOIN account a ON t.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE t.type = 'VYDAJ'	financial
SELECT AVG(T1.A15) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A15 > 4000 AND T2.date >= '1997-01-01'	financial
SELECT COUNT(T1.card_id) FROM card AS T1 JOIN disp AS T2 ON T1.disp_id = T2.disp_id WHERE T1.type = 'classic' AND T2.type = 'OWNER'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'M' AND T2.A2 = 'Hl.m. Praha'	financial
SELECT CAST(SUM(type = 'gold' AND STRFTIME('%Y', issued) < '1998') AS REAL) * 100 / COUNT(card_id) FROM card	financial
SELECT c.client_id FROM loan l JOIN account a ON l.account_id = a.account_id JOIN disp d ON a.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE d.type = 'OWNER' ORDER BY l.amount DESC LIMIT 1	financial
SELECT d.A15 FROM account a JOIN district d ON a.district_id = d.district_id WHERE a.account_id = 532	financial
SELECT account.district_id FROM "order" JOIN account ON "order".account_id = account.account_id WHERE "order".order_id = 33333	financial
SELECT t.trans_id FROM trans t JOIN account a ON t.account_id = a.account_id JOIN disp d ON a.account_id = d.account_id WHERE d.client_id = 3356 AND t.operation = 'VYBER'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN loan AS T2 ON T1.account_id = T2.account_id WHERE T1.frequency = 'POPLATEK TYDNE' AND T2.amount < 200000	financial
SELECT card.type FROM client JOIN disp ON client.client_id = disp.client_id JOIN card ON disp.disp_id = card.disp_id WHERE client.client_id = 13539	financial
SELECT d.A3 FROM client c JOIN district d ON c.district_id = d.district_id WHERE c.client_id = 3541	financial
SELECT d.A2 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.status = 'A' GROUP BY d.district_id, d.A2 ORDER BY COUNT(*) DESC LIMIT 1	financial
SELECT d.client_id FROM "order" o JOIN disp d ON o.account_id = d.account_id WHERE o.order_id = 32423	financial
SELECT t.trans_id FROM trans t JOIN account a ON t.account_id = a.account_id WHERE a.district_id = 5	financial
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A2 = 'Jesenik'	financial
SELECT c.client_id FROM card ca JOIN disp d ON ca.disp_id = d.disp_id JOIN client c ON d.client_id = c.client_id WHERE ca.type = 'junior' AND ca.issued >= '1997-01-01'	financial
SELECT CAST(SUM(T2.gender = 'F') AS REAL) * 100 / COUNT(T2.client_id) FROM district AS T1 JOIN account AS T3 ON T1.district_id = T3.district_id JOIN disp AS T4 ON T3.account_id = T4.account_id JOIN client AS T2 ON T4.client_id = T2.client_id WHERE T1.A11 > 10000	financial
SELECT CAST((SUM(CASE WHEN STRFTIME('%Y', loan.date) = '1997' THEN loan.amount ELSE 0 END) - SUM(CASE WHEN STRFTIME('%Y', loan.date) = '1996' THEN loan.amount ELSE 0 END)) AS REAL) * 100 / SUM(CASE WHEN STRFTIME('%Y', loan.date) = '1996' THEN loan.amount ELSE 0 END) FROM loan JOIN account ON loan.account_id = account.account_id JOIN disp ON account.account_id = disp.account_id JOIN client ON disp.client_id = client.client_id WHERE client.gender = 'M' AND STRFTIME('%Y', loan.date) IN ('1996', '1997')	financial
SELECT COUNT(account_id) FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) > '1995'	financial
SELECT SUM(IIF(A3 = 'east Bohemia', A16, 0)) - SUM(IIF(A3 = 'north Bohemia', A16, 0)) FROM district	financial
SELECT SUM(type = 'OWNER') AS "SUM(type = 'OWNER')", SUM(type = 'DISPONENT') AS "SUM(type = 'DISPONENT')" FROM disp WHERE account_id BETWEEN 1 AND 10	financial
SELECT a.frequency, t.k_symbol FROM account a CROSS JOIN (SELECT DISTINCT k_symbol FROM trans WHERE amount = 3539 AND type = 'VYDAJ') t WHERE a.account_id = 3	financial
SELECT STRFTIME('%Y', T1.birth_date) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id WHERE T2.account_id = 130 AND T2.type = 'OWNER'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN disp AS T2 ON T1.account_id = T2.account_id WHERE T2.type = 'OWNER' AND T1.frequency = 'POPLATEK PO OBRATU'	financial
SELECT l.amount, l.status FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN loan l ON a.account_id = l.account_id WHERE c.client_id = 992	financial
SELECT t.balance, c.gender FROM trans t JOIN disp d ON t.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE t.trans_id = 851 AND c.client_id = 4	financial
SELECT card.type FROM client JOIN disp ON client.client_id = disp.client_id JOIN card ON disp.disp_id = card.disp_id WHERE client.client_id = 9	financial
SELECT SUM(T3.amount) FROM client T1 JOIN disp T2 ON T1.client_id = T2.client_id JOIN account T4 ON T2.account_id = T4.account_id JOIN trans T3 ON T4.account_id = T3.account_id WHERE T1.client_id = 617 AND STRFTIME('%Y', T3.date) = '1998' AND T3.type IN ('VYDAJ', 'VYBER')	financial
SELECT client.client_id, account.account_id FROM client JOIN disp ON client.client_id = disp.client_id JOIN account ON disp.account_id = account.account_id JOIN district ON account.district_id = district.district_id WHERE CAST(STRFTIME('%Y', client.birth_date) AS INTEGER) BETWEEN 1983 AND 1987 AND district.A3 = 'east Bohemia'	financial
SELECT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN loan l ON a.account_id = l.account_id WHERE c.gender = 'F' ORDER BY l.amount DESC LIMIT 3	financial
SELECT COUNT(T4.account_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN account AS T3 ON T2.account_id = T3.account_id JOIN trans AS T4 ON T3.account_id = T4.account_id WHERE T1.gender = 'M' AND CAST(STRFTIME('%Y', T1.birth_date) AS INTEGER) BETWEEN 1974 AND 1976 AND T4.k_symbol = 'SIPO' AND T4.amount > 4000	financial
SELECT COUNT(account_id) FROM account JOIN district ON account.district_id = district.district_id WHERE district.A2 = 'Beroun' AND STRFTIME('%Y', account.date) > '1996'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN disp AS T2 ON T1.client_id = T2.client_id INNER JOIN card AS T3 ON T2.disp_id = T3.disp_id WHERE T1.gender = 'F' AND T3.type = 'junior'	financial
SELECT CAST(SUM(T2.gender = 'F') AS REAL) / COUNT(T2.client_id) * 100 FROM district AS T1 JOIN account AS T3 ON T1.district_id = T3.district_id JOIN disp AS T4 ON T3.account_id = T4.account_id JOIN client AS T2 ON T4.client_id = T2.client_id WHERE T1.A3 = 'Prague'	financial
SELECT CAST(SUM(T1.gender = 'M') AS REAL) * 100 / COUNT(T1.client_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN account AS T3 ON T2.account_id = T3.account_id WHERE T3.frequency = 'POPLATEK TYDNE'	financial
SELECT COUNT(disp.account_id) FROM account JOIN disp ON account.account_id = disp.account_id WHERE account.frequency = 'POPLATEK TYDNE' AND disp.type = 'OWNER'	financial
SELECT l.account_id FROM loan l JOIN account a ON l.account_id = a.account_id WHERE l.duration > 24 AND a.date < '1997-01-01' AND l.amount = ( SELECT MIN(l2.amount) FROM loan l2 JOIN account a2 ON l2.account_id = a2.account_id WHERE l2.duration > 24 AND a2.date < '1997-01-01' )	financial
SELECT a.account_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN district dist ON a.district_id = dist.district_id WHERE c.gender = 'F' ORDER BY c.birth_date ASC, CAST(dist.A11 AS INTEGER) ASC LIMIT 1	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE STRFTIME('%Y', T1.birth_date) = '1920' AND T2.A3 = 'east Bohemia'	financial
SELECT COUNT(a.account_id) FROM loan l JOIN account a ON l.account_id = a.account_id WHERE l.duration = 24 AND a.frequency = 'POPLATEK TYDNE'	financial
SELECT AVG(T1.amount) FROM loan AS T1 INNER JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.status IN ('C', 'D') AND T2.frequency = 'POPLATEK PO OBRATU'	financial
SELECT c.client_id, d.district_id, d.A2 FROM client c JOIN disp di ON c.client_id = di.client_id JOIN account a ON di.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE di.type = 'OWNER'	financial
SELECT T1.client_id, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.birth_date) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN card AS T3 ON T2.disp_id = T3.disp_id WHERE T3.type = 'gold' AND T2.type = 'OWNER'	financial
SELECT bond_type FROM bond GROUP BY bond_type ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '-' AND a.element = 'cl'	toxicology
SELECT AVG(oxygen_count) FROM ( SELECT b.molecule_id, COUNT(CASE WHEN a.element = 'o' THEN 1 END) AS oxygen_count FROM bond b JOIN atom a ON b.molecule_id = a.molecule_id WHERE b.bond_type = '-' GROUP BY b.molecule_id )	toxicology
SELECT AVG(single_bond_count) FROM (SELECT m.molecule_id, COUNT(CASE WHEN b.bond_type = '-' THEN 1 END) AS single_bond_count FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '+' GROUP BY m.molecule_id)	toxicology
SELECT COUNT(DISTINCT T2.molecule_id) FROM atom AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.element = 'na' AND T2.label = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE b.bond_type = '#' AND m.label = '+'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T1.element = 'c' THEN T1.atom_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T1.atom_id) FROM atom AS T1 INNER JOIN bond AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.bond_type = '='	toxicology
SELECT COUNT(bond_id) FROM bond WHERE bond_type = '#'	toxicology
SELECT COUNT(DISTINCT atom_id) FROM atom WHERE element != 'br'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE molecule_id BETWEEN 'TR000' AND 'TR099' AND label = '+'	toxicology
SELECT DISTINCT molecule_id FROM atom WHERE element = 'c'	toxicology
SELECT DISTINCT a.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON (a.atom_id = c.atom_id OR a.atom_id = c.atom_id2) WHERE b.bond_id = 'TR004_8_9'	toxicology
SELECT element FROM ( SELECT a1.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id WHERE b.bond_type = '=' UNION SELECT a2.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE b.bond_type = '=' ) ORDER BY element	toxicology
SELECT m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.element = 'h' GROUP BY m.label ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'cl'	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '-'	toxicology
SELECT atom.atom_id FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '-'	toxicology
SELECT element FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '-' GROUP BY element ORDER BY COUNT(*) ASC LIMIT 1	toxicology
SELECT DISTINCT b.bond_type FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE (c.atom_id = 'TR004_8' AND c.atom_id2 = 'TR004_20') OR (c.atom_id = 'TR004_20' AND c.atom_id2 = 'TR004_8')	toxicology
SELECT DISTINCT label FROM molecule WHERE label NOT IN ( SELECT DISTINCT m.label FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'sn' )	toxicology
SELECT COUNT(DISTINCT CASE WHEN a.element = 'i' THEN a.atom_id END) AS iodine_nums, COUNT(DISTINCT CASE WHEN a.element = 's' THEN a.atom_id END) AS sulfur_nums FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '-'	toxicology
SELECT connected.atom_id, connected.atom_id2 FROM connected JOIN bond ON connected.bond_id = bond.bond_id WHERE bond.bond_type = '#'	toxicology
SELECT c.atom_id, c.atom_id2 FROM atom a JOIN connected c ON a.atom_id = c.atom_id WHERE a.molecule_id = 'TR181'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T1.element <> 'f' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T2.molecule_id) FROM atom AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '+'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T2.label = '+' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T2.molecule_id) AS percentage FROM bond AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '#'	toxicology
SELECT element FROM (SELECT element, COUNT(*) as cnt FROM atom WHERE molecule_id = 'TR000' GROUP BY element ORDER BY cnt DESC LIMIT 3) ORDER BY element ASC	toxicology
SELECT atom_id AS atom_id1, atom_id2 FROM connected WHERE bond_id = 'TR001_2_6'	toxicology
SELECT SUM(CASE WHEN label = '+' THEN 1 ELSE 0 END) - SUM(CASE WHEN label = '-' THEN 1 ELSE 0 END) AS diff_car_notcar FROM molecule	toxicology
SELECT atom_id FROM connected WHERE bond_id = 'TR000_2_5' UNION SELECT atom_id2 FROM connected WHERE bond_id = 'TR000_2_5'	toxicology
SELECT bond_id FROM connected WHERE atom_id2 = 'TR000_2'	toxicology
SELECT DISTINCT molecule_id FROM bond WHERE bond_type = '=' ORDER BY molecule_id ASC LIMIT 5	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN bond_type = '=' THEN bond_id ELSE NULL END) AS REAL) * 100 / COUNT(bond_id), 5) FROM bond WHERE molecule_id = 'TR008'	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T.label = '+' THEN T.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(T.molecule_id), 3) FROM molecule AS T	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T.element = 'h' THEN T.atom_id ELSE NULL END) AS REAL) * 100 / COUNT(T.atom_id), 4) FROM atom AS T WHERE T.molecule_id = 'TR206'	toxicology
SELECT DISTINCT bond_type FROM bond WHERE molecule_id = 'TR000'	toxicology
SELECT a.element, m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE m.molecule_id = 'TR060'	toxicology
SELECT bond_type FROM bond WHERE molecule_id = 'TR010' GROUP BY bond_type ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND b.bond_type = '-' ORDER BY m.molecule_id LIMIT 3	toxicology
SELECT bond_id FROM bond WHERE molecule_id = 'TR006' ORDER BY bond_id ASC LIMIT 2	toxicology
SELECT COUNT(T2.bond_id) FROM connected AS T1 JOIN bond AS T2 ON T1.bond_id = T2.bond_id WHERE T2.molecule_id = 'TR009' AND (T1.atom_id = 'TR009_12' OR T1.atom_id2 = 'TR009_12')	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '+' AND a.element = 'br'	toxicology
SELECT b.bond_type, c.atom_id, c.atom_id2 FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.bond_id = 'TR001_6_9'	toxicology
SELECT m.molecule_id, IIF(m.label = '+', 'YES', 'NO') AS flag_carcinogenic FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR001_10'	toxicology
SELECT COUNT(DISTINCT molecule_id) FROM bond WHERE bond_type = '#'	toxicology
SELECT COUNT(T.bond_id) FROM connected AS T WHERE T.atom_id LIKE 'TR%_19'	toxicology
SELECT element FROM atom WHERE molecule_id = 'TR004'	toxicology
SELECT COUNT(molecule_id) AS "COUNT(T.molecule_id)" FROM molecule WHERE label = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE SUBSTR(a.atom_id, 7, 2) BETWEEN '21' AND '25' AND m.label = '+'	toxicology
SELECT DISTINCT c.bond_id FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE (a1.element = 'p' AND a2.element = 'n') OR (a1.element = 'n' AND a2.element = 'p')	toxicology
SELECT m.label FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE b.bond_type = '=' GROUP BY m.molecule_id, m.label ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT CAST(COUNT(T2.bond_id) AS REAL) / COUNT(T1.atom_id) FROM atom T1 LEFT JOIN connected T2 ON T1.atom_id = T2.atom_id WHERE T1.element = 'i'	toxicology
SELECT b.bond_type, b.bond_id FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE CAST(SUBSTR(a.atom_id, 7, 2) AS INTEGER) = 45	toxicology
SELECT DISTINCT element FROM atom WHERE atom_id NOT IN (SELECT atom_id FROM connected)	toxicology
SELECT c.atom_id, c.atom_id2 FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.molecule_id = 'TR041' AND b.bond_type = '#'	toxicology
SELECT element FROM atom WHERE atom_id IN (SELECT atom_id FROM connected WHERE bond_id = 'TR144_8_19' UNION SELECT atom_id2 FROM connected WHERE bond_id = 'TR144_8_19')	toxicology
SELECT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '+' AND b.bond_type = '=' GROUP BY m.molecule_id ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT element FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '+' GROUP BY element ORDER BY COUNT(*) ASC LIMIT 1	toxicology
SELECT a.atom_id, c.atom_id2 FROM atom a JOIN connected c ON a.atom_id = c.atom_id WHERE a.element = 'pb'	toxicology
SELECT a1.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id WHERE b.bond_type = '#' UNION ALL SELECT a2.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE b.bond_type = '#'	toxicology
SELECT CAST((SELECT COUNT(*) FROM (SELECT T1.element AS e1, T2.element AS e2 FROM connected AS C INNER JOIN atom AS T1 ON C.atom_id = T1.atom_id INNER JOIN atom AS T2 ON C.atom_id2 = T2.atom_id) GROUP BY e1, e2 ORDER BY COUNT(*) DESC LIMIT 1) AS REAL) * 100 / (SELECT COUNT(*) FROM connected) AS percentage	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T2.label = '+' THEN T1.bond_id ELSE NULL END) AS REAL) * 100 / COUNT(T1.bond_id), 5) FROM bond AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '-'	toxicology
SELECT COUNT(atom_id) FROM atom WHERE element IN ('c', 'h')	toxicology
SELECT connected.atom_id2 FROM atom JOIN connected ON atom.atom_id = connected.atom_id WHERE atom.element = 's'	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'sn'	toxicology
SELECT COUNT(DISTINCT atom.element) FROM bond JOIN atom ON bond.molecule_id = atom.molecule_id WHERE bond.bond_type = '-'	toxicology
SELECT COUNT(T1.atom_id) FROM atom AS T1 WHERE T1.molecule_id IN ( SELECT DISTINCT b.molecule_id FROM bond b WHERE b.bond_type = '#' AND b.molecule_id IN ( SELECT DISTINCT a.molecule_id FROM atom a WHERE a.element IN ('p', 'br') ) )	toxicology
SELECT b.bond_id FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE m.label = '+'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND b.bond_type = '-'	toxicology
SELECT CAST(COUNT(CASE WHEN a.element = 'cl' THEN a.atom_id ELSE NULL END) AS REAL) * 100 / COUNT(a.atom_id) FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE b.bond_type = '-'	toxicology
SELECT molecule_id, label FROM molecule WHERE molecule_id IN ('TR000', 'TR001', 'TR002')	toxicology
SELECT molecule_id FROM molecule WHERE label = '-'	toxicology
SELECT COUNT(T.molecule_id) FROM molecule AS T WHERE T.label = '+' AND T.molecule_id BETWEEN 'TR000' AND 'TR030'	toxicology
SELECT molecule_id, bond_type FROM bond WHERE molecule_id BETWEEN 'TR000' AND 'TR050'	toxicology
SELECT DISTINCT a1.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id WHERE c.bond_id = 'TR001_10_11' UNION SELECT DISTINCT a2.element FROM connected c JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR001_10_11'	toxicology
SELECT COUNT(T2.bond_id) FROM atom AS T1 INNER JOIN connected AS T2 ON T1.atom_id = T2.atom_id WHERE T1.element = 'i'	toxicology
SELECT MAX(m.label) AS label FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'ca'	toxicology
SELECT c.bond_id, c.atom_id2, a.element AS flag_have_CaCl FROM connected c JOIN atom a ON c.atom_id2 = a.atom_id WHERE c.bond_id = 'TR001_1_8' AND a.element IN ('c', 'cl')	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND a.element = 'c' AND b.bond_type = '#' LIMIT 2	toxicology
SELECT CAST(SUM(CASE WHEN a.element = 'cl' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) AS percentage FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE m.label = '+'	toxicology
SELECT DISTINCT element FROM atom WHERE molecule_id = 'TR001'	toxicology
SELECT DISTINCT molecule_id FROM bond WHERE bond_type = '='	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '#'	toxicology
SELECT a.element FROM connected c JOIN atom a ON c.atom_id = a.atom_id WHERE c.bond_id = 'TR000_1_2' UNION SELECT a.element FROM connected c JOIN atom a ON c.atom_id2 = a.atom_id WHERE c.bond_id = 'TR000_1_2'	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND b.bond_type = '-'	toxicology
SELECT m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_id = 'TR001_10_11'	toxicology
SELECT b.bond_id, m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_type = '#'	toxicology
SELECT atom.element FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '+' AND substr(atom.atom_id, 7, 1) = '4'	toxicology
SELECT CAST(SUM(CASE WHEN a.element = 'h' THEN 1 ELSE 0 END) AS REAL) / COUNT(*) AS ratio, m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.molecule_id = 'TR006' GROUP BY m.label	toxicology
SELECT m.label AS flag_carcinogenic FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'ca'	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'c'	toxicology
SELECT a1.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR001_10_11' UNION SELECT a2.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR001_10_11'	toxicology
SELECT CAST(COUNT(CASE WHEN bond_type = '#' THEN bond_id ELSE NULL END) AS REAL) * 100 / COUNT(bond_id) FROM bond	toxicology
SELECT CAST(COUNT(CASE WHEN bond_type = '=' THEN bond_id ELSE NULL END) AS REAL) * 100 / COUNT(bond_id) FROM bond WHERE molecule_id = 'TR047'	toxicology
SELECT m.label AS flag_carcinogenic FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR001_1'	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR151'	toxicology
SELECT DISTINCT element FROM atom WHERE molecule_id = 'TR151'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '+'	toxicology
SELECT atom_id FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE element = 'c' AND CAST(substr(molecule.molecule_id, 3, 3) AS INTEGER) >= 10 AND CAST(substr(molecule.molecule_id, 3, 3) AS INTEGER) <= 50	toxicology
SELECT COUNT(T1.atom_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '+'	toxicology
SELECT b.bond_id FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_type = '=' AND m.label = '+'	toxicology
SELECT COUNT(*) AS atomnums_h FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE atom.element = 'h' AND molecule.label = '+'	toxicology
SELECT DISTINCT b.molecule_id, b.bond_id, CASE WHEN c.atom_id = 'TR000_1' THEN c.atom_id WHEN c.atom_id2 = 'TR000_1' THEN c.atom_id2 END AS atom_id FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.bond_id = 'TR000_1_2' AND (c.atom_id = 'TR000_1' OR c.atom_id2 = 'TR000_1')	toxicology
SELECT a.atom_id FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.element = 'c' AND m.label = '-'	toxicology
SELECT CAST(COUNT(CASE WHEN T1.element = 'h' AND T2.label = '+' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(T2.molecule_id) FROM atom AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR124'	toxicology
SELECT atom_id FROM atom WHERE molecule_id = 'TR186'	toxicology
SELECT bond_type FROM bond WHERE bond_id = 'TR007_4_19'	toxicology
SELECT a1.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id WHERE b.bond_id = 'TR001_2_4' UNION SELECT a2.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE b.bond_id = 'TR001_2_4'	toxicology
SELECT COUNT(T1.bond_id), T2.label FROM bond AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.molecule_id = 'TR006' AND T1.bond_type = '='	toxicology
SELECT m.molecule_id, a.element FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '+'	toxicology
SELECT c.bond_id, c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '-'	toxicology
SELECT DISTINCT b.molecule_id, a.element FROM bond b JOIN atom a ON b.molecule_id = a.molecule_id WHERE b.bond_type = '#'	toxicology
SELECT a.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON c.atom_id = a.atom_id WHERE b.bond_id = 'TR000_2_3'	toxicology
SELECT COUNT(T1.bond_id) FROM bond AS T1 JOIN connected AS T2 ON T1.bond_id = T2.bond_id JOIN atom AS T3 ON T2.atom_id = T3.atom_id OR T2.atom_id2 = T3.atom_id WHERE T3.element = 'cl'	toxicology
SELECT a.atom_id, COUNT(DISTINCT b.bond_type), a.molecule_id FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE a.molecule_id = 'TR346' GROUP BY a.atom_id, a.molecule_id	toxicology
SELECT COUNT(*), SUM(CASE WHEN label = '+' THEN 1 ELSE 0 END) FROM (SELECT DISTINCT T2.molecule_id, T2.label FROM bond AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '=') AS sub	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m WHERE m.molecule_id NOT IN ( SELECT DISTINCT a.molecule_id FROM atom a WHERE a.element = 's' ) AND m.molecule_id NOT IN ( SELECT DISTINCT b.molecule_id FROM bond b WHERE b.bond_type = '=' )	toxicology
SELECT m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_id = 'TR001_2_4'	toxicology
SELECT COUNT(atom_id) FROM atom WHERE molecule_id = 'TR001'	toxicology
SELECT COUNT(T.bond_id) FROM bond AS T WHERE T.bond_type = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'cl' AND m.label = '+'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'c' AND m.label = '-'	toxicology
SELECT COUNT(CASE WHEN T2.label = '+' AND T1.element = 'cl' THEN T2.molecule_id ELSE NULL END) * 100 / COUNT(T2.molecule_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id	toxicology
SELECT molecule_id FROM bond WHERE bond_id = 'TR001_1_7'	toxicology
SELECT COUNT(DISTINCT a.element) FROM connected c JOIN atom a ON (a.atom_id = c.atom_id OR a.atom_id = c.atom_id2) WHERE c.bond_id = 'TR001_3_4'	toxicology
SELECT DISTINCT b.bond_type FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE (c.atom_id = 'TR000_1' AND c.atom_id2 = 'TR000_2') OR (c.atom_id = 'TR000_2' AND c.atom_id2 = 'TR000_1')	toxicology
SELECT a1.molecule_id FROM atom a1 JOIN atom a2 ON a1.molecule_id = a2.molecule_id WHERE a1.atom_id = 'TR000_2' AND a2.atom_id = 'TR000_4'	toxicology
SELECT element FROM atom WHERE atom_id = 'TR000_1'	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR000'	toxicology
SELECT CAST(SUM(bond_type = '-') AS REAL) * 100 / COUNT(bond_id) AS percentage FROM bond	toxicology
SELECT COUNT(DISTINCT T1.molecule_id) FROM molecule AS T1 INNER JOIN atom AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.label = '+' AND T2.element = 'n'	toxicology
SELECT DISTINCT a.molecule_id FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE a.element = 's' AND b.bond_type = '='	toxicology
SELECT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '-' GROUP BY m.molecule_id HAVING COUNT(a.atom_id) > 5	toxicology
SELECT DISTINCT a.element FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE b.molecule_id = 'TR024' AND b.bond_type = '='	toxicology
SELECT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '+' GROUP BY m.molecule_id ORDER BY COUNT(a.atom_id) DESC LIMIT 1	toxicology
SELECT CAST(SUM(CASE WHEN m.label = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id JOIN bond b ON m.molecule_id = b.molecule_id WHERE a.element = 'h' AND b.bond_type = '#'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '+'	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.molecule_id BETWEEN 'TR004' AND 'TR010' AND b.bond_type = '-'	toxicology
SELECT COUNT(atom.atom_id) FROM atom WHERE atom.molecule_id = 'TR008' AND atom.element = 'c'	toxicology
SELECT a.element FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR004_7' AND m.label = '-'	toxicology
SELECT COUNT(DISTINCT a.molecule_id) FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'o' AND b.bond_type = '='	toxicology
SELECT COUNT(DISTINCT T1.molecule_id) FROM molecule AS T1 INNER JOIN bond AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.bond_type = '#' AND T1.label = '-'	toxicology
SELECT DISTINCT a.element, b.bond_type FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON (a.atom_id = c.atom_id OR a.atom_id = c.atom_id2) WHERE b.molecule_id = 'TR002'	toxicology
SELECT a.atom_id FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'c' AND b.bond_type = '=' AND a.molecule_id = 'TR012'	toxicology
SELECT a.atom_id FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE m.label = '+' AND a.element = 'o'	toxicology
SELECT id FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT id FROM cards WHERE borderColor = 'borderless' AND (cardKingdomId IS NULL OR cardKingdomFoilId IS NULL)	card_games
SELECT DISTINCT name FROM cards WHERE faceConvertedManaCost = (SELECT MAX(faceConvertedManaCost) FROM cards WHERE faceConvertedManaCost IS NOT NULL)	card_games
SELECT id FROM cards WHERE CAST(frameVersion AS INTEGER) = 2015 AND edhrecRank < 100	card_games
SELECT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.rarity = 'mythic' AND l.format = 'gladiator' AND l.status = 'Banned'	card_games
SELECT l.status FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.types = 'Artifact' AND c.side IS NULL AND l.format = 'vintage'	card_games
SELECT c.id, c.artist FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE l.format = 'commander' AND l.status = 'Legal' AND (c.power = '*' OR c.power IS NULL)	card_games
SELECT cards.id, rulings.text, cards.hasContentWarning FROM cards JOIN rulings ON cards.uuid = rulings.uuid WHERE cards.artist = 'Stephen Daniele'	card_games
SELECT r.text FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.name = 'Sublime Epiphany' AND c.number = '74s'	card_games
SELECT c.name, c.artist, c.isPromo FROM cards c JOIN rulings r ON c.uuid = r.uuid GROUP BY c.uuid, c.name, c.artist, c.isPromo ORDER BY COUNT(r.uuid) DESC LIMIT 1	card_games
SELECT "language" FROM "foreign_data" fd JOIN "cards" c ON fd."uuid" = c."uuid" WHERE c."name" = 'Annul' AND c."number" = '29'	card_games
SELECT DISTINCT c.name FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE f.language = 'Japanese'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'Chinese Simplified' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 LEFT JOIN foreign_data AS T2 ON T1.uuid = T2.uuid	card_games
SELECT s.name, s.totalSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.language = 'Italian'	card_games
SELECT COUNT(DISTINCT type) AS "COUNT(type)" FROM cards WHERE artist = 'Aaron Boyd'	card_games
SELECT DISTINCT keywords FROM cards WHERE name = 'Angel of Mercy'	card_games
SELECT COUNT(*) FROM cards WHERE power = '*'	card_games
SELECT DISTINCT promoTypes FROM cards WHERE name = 'Duress' AND promoTypes IS NOT NULL	card_games
SELECT DISTINCT borderColor FROM cards WHERE name = 'Ancestor''s Chosen'	card_games
SELECT originalType FROM cards WHERE name = 'Ancestor''s Chosen'	card_games
SELECT DISTINCT st.language FROM cards c JOIN sets s ON c.setCode = s.code JOIN set_translations st ON s.code = st.setCode WHERE c.name = 'Angel of Mercy'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Restricted' AND T1.isTextless = 0	card_games
SELECT DISTINCT rulings.text FROM rulings JOIN cards ON rulings.uuid = cards.uuid WHERE cards.name = 'Condemn'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Restricted' AND T1.isStarter = 1	card_games
SELECT DISTINCT l.status FROM legalities l JOIN cards c ON l.uuid = c.uuid WHERE c.name = 'Cloudchaser Eagle'	card_games
SELECT DISTINCT type FROM cards WHERE name = 'Benalish Knight'	card_games
SELECT DISTINCT l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.name = 'Benalish Knight'	card_games
SELECT c.artist FROM foreign_data f JOIN cards c ON f.uuid = c.uuid WHERE f.language = 'Phyrexian'	card_games
SELECT CAST(SUM(CASE WHEN borderColor = 'borderless' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(id) FROM cards	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T2.language = 'German' AND T1.isReprint = 1	card_games
SELECT COUNT(T1.id) FROM cards AS T1 JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T1.borderColor = 'borderless' AND T2.language = 'Russian'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'French' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 INNER JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T1.isStorySpotlight = 1	card_games
SELECT COUNT(id) FROM cards WHERE toughness = '99'	card_games
SELECT DISTINCT name FROM cards WHERE artist = 'Aaron Boyd'	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'black' AND availability = 'mtgo'	card_games
SELECT id FROM cards WHERE convertedManaCost = 0	card_games
SELECT DISTINCT layout FROM cards WHERE keywords LIKE '%Flying%'	card_games
SELECT COUNT(id) FROM cards WHERE originalType = 'Summon - Angel' AND subtypes != 'Angel'	card_games
SELECT id FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT id FROM cards WHERE duelDeck = 'a'	card_games
SELECT edhrecRank FROM cards WHERE frameVersion = '2015'	card_games
SELECT DISTINCT c.artist FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE fd.language = 'Chinese Simplified'	card_games
SELECT DISTINCT c.name FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE c.availability = 'paper' AND f.language = 'Japanese'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Banned' AND T1.borderColor = 'white'	card_games
SELECT l.uuid, f.language FROM legalities l JOIN foreign_data f ON l.uuid = f.uuid WHERE l.format = 'legacy'	card_games
SELECT r.text FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.name = 'Beacon of Immortality'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 WHERE T1.frameVersion = 'future'	card_games
SELECT id, colors FROM cards WHERE setCode = 'OGW'	card_games
SELECT c.id, f.language FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE c.setCode = '10E' AND c.convertedManaCost = 5	card_games
SELECT c.id, r.date FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.originalType = 'Creature - Elf'	card_games
SELECT c.colors, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.id BETWEEN 1 AND 20	card_games
SELECT DISTINCT c.name FROM cards c INNER JOIN foreign_data f ON c.uuid = f.uuid WHERE c.originalType = 'Artifact' AND c.colors = 'B'	card_games
SELECT DISTINCT c.name FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.rarity = 'uncommon' ORDER BY r.date ASC LIMIT 3	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'John Avon' AND NOT (cardKingdomId IS NOT NULL AND cardKingdomFoilId IS NOT NULL)	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'white' AND cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'UDON' AND availability = 'mtgo' AND hand = '-1'	card_games
SELECT COUNT(id) FROM cards WHERE frameVersion = '1993' AND availability = 'paper' AND hasContentWarning = 1	card_games
SELECT manaCost FROM cards WHERE layout = 'normal' AND frameVersion = '2003' AND borderColor = 'black' AND availability = 'mtgo,paper'	card_games
SELECT manaCost FROM cards WHERE artist = 'Rob Alexander'	card_games
SELECT DISTINCT subtypes, supertypes FROM cards WHERE availability = 'arena' AND (subtypes IS NOT NULL OR supertypes IS NOT NULL)	card_games
SELECT setCode FROM set_translations WHERE language = 'Spanish'	card_games
SELECT SUM(CASE WHEN isOnlineOnly = 1 THEN 1.0 ELSE 0 END) / COUNT(id) * 100 FROM cards WHERE frameEffects LIKE '%legendary%'	card_games
SELECT CAST(SUM(CASE WHEN isTextless = 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(id) FROM cards WHERE isStorySpotlight = 1	card_games
SELECT (SELECT CAST(SUM(CASE WHEN language = 'Spanish' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM foreign_data) AS percentage, name FROM foreign_data WHERE language = 'Spanish'	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.baseSetSize = 309	card_games
SELECT COUNT(T1.id) FROM set_translations AS T1 JOIN sets AS T2 ON T1.setCode = T2.code WHERE T1.language = 'Portuguese (Brazil)' AND T2.block = 'Commander'	card_games
SELECT DISTINCT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.types LIKE '%Creature%' AND l.status = 'Legal'	card_games
SELECT DISTINCT c.subtypes, c.supertypes FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE f.language = 'German' AND c.subtypes IS NOT NULL AND c.supertypes IS NOT NULL	card_games
SELECT r.text FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE (c.power IS NULL OR c.power = '*') AND r.text LIKE '%triggered ability%'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid INNER JOIN rulings AS T3 ON T1.uuid = T3.uuid WHERE T2.format = 'premodern' AND T3.text = 'This is a triggered mana ability.' AND T1.side IS NULL	card_games
SELECT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.artist = 'Erica Yang' AND l.format = 'pauper' AND l.status = 'Legal' AND c.availability = 'paper'	card_games
SELECT c.artist FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE TRIM(f.text) = 'Das perfekte Gegenmittel zu einer dichten Formation'	card_games
SELECT fd.name FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE fd.language = 'French' AND c.types LIKE '%Creature%' AND c.layout = 'normal' AND c.borderColor = 'black' AND c.artist = 'Matthew D. Wilson'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN rulings AS T2 ON T1.uuid = T2.uuid WHERE T1.rarity = 'rare' AND T2.date = '2007-02-01'	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE TRIM(s.block) = 'Ravnica' AND s.baseSetSize = 180	card_games
SELECT CAST(SUM(CASE WHEN c.hasContentWarning = 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(c.id) FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE l.format = 'commander' AND l.status = 'Legal'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'French' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards T1 LEFT JOIN foreign_data T2 ON T1.uuid = T2.uuid WHERE T1.power IS NULL OR T1.power = '*'	card_games
SELECT CAST(SUM(CASE WHEN st.language = 'Japanese' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.id) FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.type = 'expansion'	card_games
SELECT DISTINCT availability FROM cards WHERE artist = 'Daren Bader'	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'borderless' AND edhrecRank > 12000	card_games
SELECT COUNT(id) FROM cards WHERE isOversized = 1 AND isReprint = 1 AND isPromo = 1	card_games
SELECT name FROM cards WHERE (power IS NULL OR power = '*') AND promoTypes = 'arenaleague' ORDER BY name LIMIT 3	card_games
SELECT language FROM foreign_data WHERE multiverseid = 149934	card_games
SELECT cardKingdomFoilId, cardKingdomId FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL ORDER BY cardKingdomFoilId ASC LIMIT 3	card_games
SELECT CAST(SUM(CASE WHEN isTextless = 1 AND layout = 'normal' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM cards	card_games
SELECT id FROM cards WHERE side IS NULL AND subtypes LIKE '%Angel%' AND subtypes LIKE '%Wizard%'	card_games
SELECT name FROM sets WHERE mtgoCode IS NULL OR mtgoCode = '' ORDER BY name LIMIT 3	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.mcmName = 'Archenemy' AND s.code = 'ARC'	card_games
SELECT s.name, st.translation FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.id = 5	card_games
SELECT st.language, s.type FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.id = 206	card_games
SELECT DISTINCT s.name, s.id FROM sets s JOIN cards c ON s.code = c.setCode JOIN foreign_data fd ON c.uuid = fd.uuid WHERE fd.language = 'Italian' AND s.block = 'Shadowmoor' ORDER BY s.name LIMIT 2	card_games
SELECT s.name, s.id FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.isForeignOnly = 0 AND s.isFoilOnly = 1 AND st.language = 'Japanese'	card_games
SELECT s.id FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.language = 'Russian' ORDER BY s.baseSetSize DESC LIMIT 1	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'Chinese Simplified' AND T1.isOnlineOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM cards AS T1 INNER JOIN foreign_data AS T2 ON T1.uuid = T2.uuid	card_games
SELECT COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T2.language = 'Japanese' AND (T1.mtgoCode IS NULL OR T1.mtgoCode = '')	card_games
SELECT id FROM cards WHERE borderColor = 'black'	card_games
SELECT id FROM cards WHERE frameEffects = 'extendedart'	card_games
SELECT id FROM cards WHERE borderColor = 'black' AND isFullArt = 1	card_games
SELECT st.language FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE s.id = 174	card_games
SELECT name FROM sets WHERE code = 'ALL'	card_games
SELECT DISTINCT language FROM foreign_data WHERE name = 'A Pedra Fellwar'	card_games
SELECT code AS setCode FROM sets WHERE releaseDate = '2007-07-13'	card_games
SELECT baseSetSize, code FROM sets WHERE block = 'Masques' OR block = 'Mirage'	card_games
SELECT code AS setCode FROM sets WHERE type = 'expansion'	card_games
SELECT fd.name, fd.type FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'boros'	card_games
SELECT fd.language, fd.flavorText FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'colorpie'	card_games
SELECT CAST(SUM(CASE WHEN c.convertedManaCost = 10 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(c.id), 'Abyssal Horror' FROM cards c WHERE c.setCode = (SELECT setCode FROM cards WHERE name = 'Abyssal Horror' LIMIT 1)	card_games
SELECT code AS setCode FROM sets WHERE type = 'expansion' OR type = 'commander'	card_games
SELECT fd.name, fd.type FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'abzan'	card_games
SELECT fd.language, c.type FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'azorius'	card_games
SELECT SUM(CASE WHEN artist = 'Aaron Miller' AND cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL THEN 1 ELSE 0 END) FROM cards	card_games
SELECT SUM(CASE WHEN availability = 'paper' AND hand = '3' THEN 1 ELSE 0 END) FROM cards	card_games
SELECT DISTINCT name FROM cards WHERE isTextless = 0	card_games
SELECT DISTINCT manaCost FROM cards WHERE name = 'Ancestor''s Chosen'	card_games
SELECT SUM(CASE WHEN power LIKE '%*%' OR power IS NULL THEN 1 ELSE 0 END) FROM cards WHERE borderColor = 'white'	card_games
SELECT DISTINCT name FROM cards WHERE isPromo = 1 AND side IS NOT NULL	card_games
SELECT DISTINCT subtypes, supertypes FROM cards WHERE name = 'Molimo, Maro-Sorcerer'	card_games
SELECT purchaseUrls FROM cards WHERE promoTypes = 'bundle'	card_games
SELECT COUNT(CASE WHEN availability LIKE '%arena,mtgo%' AND borderColor = 'black' THEN 1 ELSE NULL END) FROM cards	card_games
SELECT name FROM cards WHERE name IN ('Serra Angel', 'Shrine Keeper') ORDER BY convertedManaCost DESC LIMIT 1	card_games
SELECT artist FROM cards WHERE flavorName = 'Battra, Dark Destroyer'	card_games
SELECT name FROM cards WHERE frameVersion = '2003' ORDER BY convertedManaCost DESC LIMIT 3	card_games
SELECT DISTINCT st.translation FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Ancestor''s Chosen' AND st.language = 'Italian'	card_games
SELECT COUNT(DISTINCT st.translation) FROM cards c JOIN sets s ON c.setCode = s.code JOIN set_translations st ON s.code = st.setCode WHERE c.name = 'Angel of Mercy'	card_games
SELECT DISTINCT cards.name FROM cards JOIN sets ON cards.setCode = sets.code JOIN set_translations ON sets.code = set_translations.setCode WHERE set_translations.translation = 'Hauptset Zehnte Edition'	card_games
SELECT IIF(SUM(CASE WHEN T2.language = 'Korean' AND T2.translation IS NOT NULL THEN 1 ELSE 0 END) > 0, 'YES', 'NO') FROM cards T1 LEFT JOIN set_translations T2 ON T1.setCode = T2.setCode WHERE T1.name = 'Ancestor''s Chosen'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN set_translations AS T2 ON T1.setCode = T2.setCode WHERE T2.translation = 'Hauptset Zehnte Edition' AND T1.artist = 'Adam Rex'	card_games
SELECT s.baseSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Hauptset Zehnte Edition'	card_games
SELECT st.translation FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.name = 'Eighth Edition' AND st.language = 'Chinese Simplified'	card_games
SELECT IIF(MAX(CASE WHEN T2.mtgoCode IS NOT NULL THEN 1 ELSE 0 END) = 1, 'YES', 'NO') AS "IIF(T2.mtgoCode IS NOT NULL, 'YES', 'NO')" FROM cards AS T1 LEFT JOIN sets AS T2 ON T1.setCode = T2.code WHERE T1.name = 'Angel of Mercy'	card_games
SELECT DISTINCT s.releaseDate FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Ancestor''s Chosen'	card_games
SELECT s.type FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Hauptset Zehnte Edition'	card_games
SELECT COUNT(DISTINCT T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.block = 'Ice Age' AND T2.language = 'Italian' AND T2.translation IS NOT NULL	card_games
SELECT DISTINCT IIF(s.isForeignOnly = 1, 'YES', 'NO') FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Adarkar Valkyrie'	card_games
SELECT COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T2.language = 'Italian' AND T2.translation IS NOT NULL AND T1.baseSetSize < 10	card_games
SELECT SUM(CASE WHEN c.borderColor = 'black' THEN 1 ELSE 0 END) FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap'	card_games
SELECT name FROM cards WHERE setCode = 'CSP' ORDER BY convertedManaCost DESC LIMIT 1	card_games
SELECT DISTINCT c.artist FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap' AND c.artist IN ('Jeremy Jarvis', 'Aaron Miller', 'Chippy')	card_games
SELECT cards.name FROM cards JOIN sets ON cards.setCode = sets.code WHERE sets.name = 'Coldsnap' AND CAST(cards.number AS INTEGER) = 4	card_games
SELECT SUM(CASE WHEN T1.power LIKE '*' OR T1.power IS NULL THEN 1 ELSE 0 END) FROM cards AS T1 JOIN sets AS T2 ON T1.setCode = T2.code WHERE T2.name = 'Coldsnap' AND T1.convertedManaCost > 5	card_games
SELECT fd.flavorText FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE c.name = 'Ancestor''s Chosen' AND fd.language = 'Italian'	card_games
SELECT DISTINCT language FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE c.name = 'Ancestor''s Chosen' AND fd.flavorText IS NOT NULL AND fd.flavorText != ''	card_games
SELECT type FROM foreign_data WHERE language = 'German' AND name = 'Ancestor''s Chosen'	card_games
SELECT fd.text FROM cards c JOIN sets s ON c.setCode = s.code JOIN foreign_data fd ON c.uuid = fd.uuid WHERE s.name = 'Coldsnap' AND fd.language = 'Italian'	card_games
SELECT fd.name FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.setCode = 'CSP' AND fd.language = 'Italian' AND c.convertedManaCost = ( SELECT MAX(convertedManaCost) FROM cards WHERE setCode = 'CSP' )	card_games
SELECT DISTINCT r.date FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.name = 'Reminisce'	card_games
SELECT CAST(SUM(CASE WHEN T1.convertedManaCost = 7 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards T1 JOIN sets T2 ON T1.setCode = T2.code WHERE T2.name = 'Coldsnap'	card_games
SELECT CAST(SUM(CASE WHEN c.cardKingdomFoilId IS NOT NULL AND c.cardKingdomId IS NOT NULL THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(c.id) FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap'	card_games
SELECT code FROM sets WHERE releaseDate = '2017-07-14'	card_games
SELECT keyruneCode FROM sets WHERE code = 'PKHC'	card_games
SELECT mcmId FROM sets WHERE code = 'SS2'	card_games
SELECT mcmName FROM sets WHERE releaseDate = '2017-06-09'	card_games
SELECT type FROM sets WHERE name = 'From the Vault: Lore'	card_games
SELECT parentCode FROM sets WHERE name = 'Commander 2014 Oversized'	card_games
SELECT r.text, CASE WHEN c.hasContentWarning = 1 THEN 'YES' ELSE 'NO' END FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.artist = 'Jim Pavelec'	card_games
SELECT s.releaseDate FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Evacuation'	card_games
SELECT s.baseSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Rinascita di Alara'	card_games
SELECT s.type FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE st.translation = 'Huitième édition'	card_games
SELECT st.translation FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Tendo Ice Bridge' AND st.language = 'French'	card_games
SELECT COUNT(DISTINCT T2.translation) FROM sets AS T1 JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.name = 'Tenth Edition' AND T2.translation IS NOT NULL	card_games
SELECT DISTINCT st.translation FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Fellwar Stone' AND st.language = 'Japanese' AND st.translation IS NOT NULL	card_games
SELECT name FROM cards WHERE setCode = 'THP3' ORDER BY convertedManaCost DESC LIMIT 1	card_games
SELECT releaseDate FROM sets WHERE code = 'CSP'	card_games
SELECT s.type FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Samite Pilgrim'	card_games
SELECT COUNT(cards.id) FROM cards JOIN sets ON cards.setCode = sets.code WHERE sets.name = 'World Championship Decks 2004' AND cards.convertedManaCost = 3	card_games
SELECT st.translation FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE s.name = 'Mirrodin' AND st.language = 'Chinese Simplified'	card_games
SELECT CAST(SUM(CASE WHEN s.isNonFoilOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.id) FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.language = 'Japanese'	card_games
SELECT CAST(SUM(CASE WHEN c.isOnlineOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(c.id) FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE fd.language = 'Portuguese (Brazil)'	card_games
SELECT DISTINCT availability FROM cards WHERE artist = 'Aleksi Briclot' AND isTextless = 1	card_games
SELECT id FROM sets ORDER BY baseSetSize DESC LIMIT 1	card_games
SELECT artist FROM cards WHERE side IS NULL ORDER BY convertedManaCost DESC LIMIT 1	card_games
SELECT frameEffects FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL AND frameEffects IS NOT NULL GROUP BY frameEffects ORDER BY COUNT(*) DESC LIMIT 1	card_games
SELECT SUM(CASE WHEN power = '*' OR power IS NULL THEN 1 ELSE 0 END) FROM cards WHERE hasFoil = 0 AND duelDeck = 'a'	card_games
SELECT id FROM sets WHERE type = 'commander' ORDER BY totalSetSize DESC LIMIT 1	card_games
SELECT DISTINCT c.name FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE l.format = 'duel' ORDER BY c.convertedManaCost DESC LIMIT 10	card_games
WITH OldestMythic AS ( SELECT MIN(originalReleaseDate) AS min_date FROM cards WHERE rarity = 'mythic' AND originalReleaseDate IS NOT NULL ) SELECT c.originalReleaseDate, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid JOIN OldestMythic om ON c.originalReleaseDate = om.min_date WHERE c.rarity = 'mythic' AND l.status = 'Legal' ORDER BY l.format	card_games
SELECT COUNT(T3.id) FROM cards AS T1 JOIN foreign_data AS T3 ON T1.uuid = T3.uuid WHERE T1.artist = 'Volkan Baǵa' AND T3.language = 'French'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 LEFT JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T1.rarity = 'rare' AND T1.types = 'Enchantment' AND T1.name = 'Abundance' AND T2.status = 'Legal' AND NOT EXISTS ( SELECT 1 FROM legalities AS T3 WHERE T3.uuid = T1.uuid AND T3.status != 'Legal' )	card_games
WITH banned_counts AS ( SELECT l.format, COUNT(*) as banned_count FROM legalities l WHERE l.status = 'Banned' GROUP BY l.format ), max_banned_format AS ( SELECT format FROM banned_counts ORDER BY banned_count DESC LIMIT 1 ) SELECT l.format, c.name FROM legalities l JOIN cards c ON l.uuid = c.uuid JOIN max_banned_format mbf ON l.format = mbf.format WHERE l.status = 'Banned' ORDER BY c.name	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.name = 'Battlebond'	card_games
WITH artist_legal_counts AS ( SELECT c.artist, COUNT(*) as card_count FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.artist IS NOT NULL GROUP BY c.artist ), min_artist AS ( SELECT artist FROM artist_legal_counts ORDER BY card_count ASC LIMIT 1 ) SELECT c.artist, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid JOIN min_artist ma ON c.artist = ma.artist ORDER BY c.artist, l.format	card_games
SELECT l.status FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.frameVersion = '1997' AND c.artist = 'D. Alexander Gregory' AND c.hasContentWarning = 1 AND l.format = 'legacy'	card_games
SELECT DISTINCT c.name, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.edhrecRank = 1 AND l.status = 'Banned' ORDER BY c.name, l.format	card_games
SELECT (CAST(SUM(s.id) AS REAL) / COUNT(s.id)) / 4, fd.language FROM sets s JOIN cards c ON s.code = c.setCode JOIN foreign_data fd ON c.uuid = fd.uuid WHERE s.releaseDate BETWEEN '2012-01-01' AND '2015-12-31' GROUP BY fd.language ORDER BY COUNT(fd.language) DESC LIMIT 1	card_games
SELECT DISTINCT artist FROM cards WHERE BorderColor = 'black' AND availability = 'arena'	card_games
SELECT uuid FROM legalities WHERE format = 'oldschool' AND (status = 'Banned' OR status = 'Restricted')	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'Matthew D. Wilson' AND availability = 'paper'	card_games
SELECT rulings.text FROM rulings JOIN cards ON rulings.uuid = cards.uuid WHERE cards.artist = 'Kev Walker' ORDER BY rulings.date DESC	card_games
SELECT c.name, CASE WHEN l.status = 'Legal' THEN l.format ELSE NULL END FROM cards c JOIN sets s ON c.setCode = s.code LEFT JOIN legalities l ON c.uuid = l.uuid WHERE s.name = 'Hour of Devastation'	card_games
SELECT s.name FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE st.language = 'Korean' AND NOT EXISTS ( SELECT 1 FROM set_translations st2 WHERE st2.setCode = st.setCode AND st2.language = 'Japanese' )	card_games
SELECT T1.frameVersion, T1.name, IIF(T2.status = 'Banned', T1.name, 'NO') FROM cards T1 LEFT JOIN legalities T2 ON T1.uuid = T2.uuid WHERE T1.artist = 'Allen Williams'	card_games
SELECT DisplayName FROM users WHERE TRIM(DisplayName) = 'Harlan' OR TRIM(DisplayName) = 'Jarrod Dixon' ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users WHERE STRFTIME('%Y', CreationDate) = '2011'	codebase_community
SELECT COUNT(Id) FROM users WHERE LastAccessDate > '2014-09-01'	codebase_community
SELECT DisplayName FROM users ORDER BY Views DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE UpVotes > 100 AND DownVotes > 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Views > 10 AND STRFTIME('%Y', CreationDate) > '2013'	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie' AND p.Title IS NOT NULL	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(p.Title) = 'Eliciting priors from experts'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON u.Id = p.OwnerUserId WHERE TRIM(u.DisplayName) = 'csgillespie' ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.FavoriteCount IS NOT NULL ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT SUM(p.CommentCount) FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie'	codebase_community
SELECT MAX(p.AnswerCount) FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE u.DisplayName = 'csgillespie'	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(p.Title) = 'Examples for teaching: Correlation does not mean causation'	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie' AND T1.ParentId IS NULL	codebase_community
SELECT DISTINCT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ClosedDate IS NOT NULL	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T2.Age > 65 AND T1.Score >= 20	codebase_community
SELECT TRIM(u.Location) AS Location FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(p.Title) = 'Eliciting priors from experts'	codebase_community
SELECT p.Body FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id WHERE t.TagName = 'bayesian'	codebase_community
SELECT p.Body FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id ORDER BY t.Count DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.DisplayName = 'csgillespie'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie'	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie' AND STRFTIME('%Y', T1.Date) = '2011'	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM users u JOIN ( SELECT UserId, COUNT(Id) as badge_count FROM badges WHERE UserId IS NOT NULL GROUP BY UserId ORDER BY badge_count DESC LIMIT 1 ) b ON u.Id = b.UserId	codebase_community
SELECT AVG(T1.Score) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T2.DisplayName = 'csgillespie'	codebase_community
SELECT CAST(COUNT(T1.Id) AS REAL) / COUNT(DISTINCT T2.DisplayName) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.Views > 200	codebase_community
SELECT CAST(SUM(IIF(T2.Age > 65, 1, 0)) AS REAL) * 100 / COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T1.Score > 5	codebase_community
SELECT COUNT(Id) FROM votes WHERE UserId = 58 AND CreationDate = '2010-07-19'	codebase_community
SELECT CreationDate FROM votes GROUP BY CreationDate ORDER BY COUNT(Id) DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Revival'	codebase_community
SELECT p.Title FROM comments c JOIN posts p ON c.PostId = p.Id ORDER BY c.Score DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM comments AS T1 INNER JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T2.ViewCount = 1910	codebase_community
SELECT p.FavoriteCount FROM comments c JOIN posts p ON c.PostId = p.Id WHERE c.UserId = 3025 AND c.CreationDate LIKE '2014-04-23 20:29:39%'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.ParentId = 107829	codebase_community
SELECT IIF(p.ClosedDate IS NOT NULL, 'YES', 'NO') AS resylt FROM comments c JOIN posts p ON c.PostId = p.Id WHERE c.UserId = 23853 AND c.CreationDate = '2013-07-12 09:08:18.0'	codebase_community
SELECT u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 65041	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Tiago Pasqualini'	codebase_community
SELECT u.DisplayName FROM votes v JOIN users u ON v.UserId = u.Id WHERE v.Id = 6347	codebase_community
SELECT COUNT(T1.Id) FROM votes AS T1 JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T2.Title LIKE '%data visualization%'	codebase_community
SELECT b.Name FROM users u JOIN badges b ON u.Id = b.UserId WHERE TRIM(u.DisplayName) = 'DatEpicCoderGuyWhoPrograms'	codebase_community
SELECT CAST((SELECT COUNT(Id) FROM posts WHERE OwnerUserId = 24) AS REAL) / (SELECT COUNT(DISTINCT Id) FROM votes WHERE UserId = 24) AS "CAST(COUNT(T2.Id) AS REAL) / COUNT(DISTINCT T1.Id)"	codebase_community
SELECT ViewCount FROM posts WHERE TRIM(Title) = 'Integration of Weka and/or RapidMiner into Informatica PowerCenter/Developer' AND ViewCount IS NOT NULL	codebase_community
SELECT Text FROM comments WHERE Score = 17	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users WHERE WebsiteUrl = 'http://stackoverflow.com'	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'SilentGhost'	codebase_community
SELECT u.DisplayName FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Text = 'thank you user93!'	codebase_community
SELECT c.Text FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(u.DisplayName) = 'A Lion'	codebase_community
SELECT u.DisplayName, u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(p.Title) = 'Understanding what Dassault iSight is doing?'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE TRIM(p.Title) = 'How does gentle boosting differ from AdaBoost?'	codebase_community
SELECT DISTINCT u.DisplayName FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'Necromancer' LIMIT 10	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(p.Title) LIKE 'Open source tools for visualizing multi-dimensional data%'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(u.DisplayName) = 'Vebjorn Ljosa'	codebase_community
SELECT SUM(T1.Score), T2.WebsiteUrl FROM posts AS T1 JOIN users AS T2 ON T1.LastEditorUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Yevgeny'	codebase_community
SELECT c.Text AS Comment FROM comments c WHERE c.UserId IN ( SELECT DISTINCT ph.UserId FROM postHistory ph WHERE ph.PostId = 118 AND ph.PostHistoryTypeId IN (4, 5, 6) AND ph.UserId IS NOT NULL )	codebase_community
SELECT SUM(T2.BountyAmount) FROM posts AS T1 INNER JOIN votes AS T2 ON T1.Id = T2.PostId WHERE T1.Title LIKE '%data%'	codebase_community
SELECT u.DisplayName, p.Title FROM votes v JOIN posts p ON v.PostId = p.Id JOIN users u ON v.UserId = u.Id WHERE v.BountyAmount = 50 AND p.Title LIKE '%variance%'	codebase_community
SELECT AVG(p.ViewCount) OVER() AS "AVG(T2.ViewCount)", p.Title, c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE p.Tags LIKE '%<humor>%'	codebase_community
SELECT COUNT(Id) FROM comments WHERE UserId = 13	codebase_community
SELECT Id FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT Id FROM users ORDER BY Views ASC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Supporter' AND STRFTIME('%Y', Date) = '2011'	codebase_community
SELECT COUNT(UserId) FROM (SELECT UserId FROM badges GROUP BY UserId HAVING COUNT(Name) > 5)	codebase_community
SELECT COUNT(DISTINCT T1.Id) FROM users AS T1 INNER JOIN badges AS T2 ON T1.Id = T2.UserId WHERE TRIM(T1.Location) = 'New York' AND T2.Name IN ('Supporter', 'Teacher')	codebase_community
SELECT u.Id, u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 1	codebase_community
SELECT u.Id AS UserId FROM users u JOIN postHistory ph ON u.Id = ph.UserId WHERE u.Views >= 1000 GROUP BY u.Id HAVING COUNT(*) = COUNT(DISTINCT ph.PostId)	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN ( SELECT UserId FROM comments WHERE UserId IS NOT NULL GROUP BY UserId ORDER BY COUNT(Id) DESC LIMIT 1 ) AS top_user ON b.UserId = top_user.UserId	codebase_community
SELECT COUNT(T1.Id) FROM users AS T1 INNER JOIN badges AS T2 ON T1.Id = T2.UserId WHERE TRIM(T1.Location) = 'India' AND T2.Name = 'Teacher'	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', Date) = '2010', 1, 0)) AS REAL) * 100 / COUNT(Id) - CAST(SUM(IIF(STRFTIME('%Y', Date) = '2011', 1, 0)) AS REAL) * 100 / COUNT(Id) FROM badges WHERE Name = 'Student'	codebase_community
SELECT ph.PostHistoryTypeId, (SELECT COUNT(DISTINCT UserId) FROM comments WHERE PostId = 3720) AS NumberOfUsers FROM postHistory ph WHERE ph.PostId = 3720	codebase_community
SELECT p.ViewCount FROM postLinks pl JOIN posts p ON pl.RelatedPostId = p.Id WHERE pl.PostId = 61217	codebase_community
SELECT p.Score, pl.LinkTypeId FROM posts p JOIN postLinks pl ON p.Id = pl.PostId WHERE p.Id = 395	codebase_community
SELECT Id AS PostId, OwnerUserId AS UserId FROM posts WHERE Score > 60	codebase_community
SELECT SUM(DISTINCT FavoriteCount) FROM posts WHERE OwnerUserId = 686 AND STRFTIME('%Y', CreaionDate) = '2011'	codebase_community
SELECT AVG(u.UpVotes), AVG(u.Age) FROM users u JOIN ( SELECT OwnerUserId FROM posts WHERE OwnerUserId IS NOT NULL GROUP BY OwnerUserId HAVING COUNT(*) > 10 ) p ON u.Id = p.OwnerUserId	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Announcer'	codebase_community
SELECT Name FROM badges WHERE Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT COUNT(Id) FROM comments WHERE Score > 60	codebase_community
SELECT Text FROM comments WHERE CreationDate = '2010-07-19 19:16:14.0'	codebase_community
SELECT COUNT(Id) FROM posts WHERE Score = 10	codebase_community
SELECT DISTINCT b.Name AS name FROM users u JOIN badges b ON u.Id = b.UserId WHERE u.Reputation = (SELECT MAX(Reputation) FROM users)	codebase_community
SELECT DISTINCT u.Reputation FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Pierre'	codebase_community
SELECT b.Date FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.Location) = 'Rochester, NY'	codebase_community
SELECT CAST(COUNT(DISTINCT T1.UserId) AS REAL) * 100 / (SELECT COUNT(Id) FROM users) FROM badges AS T1 WHERE T1.Name = 'Teacher'	codebase_community
SELECT CAST(SUM(IIF(T2.Age BETWEEN 13 AND 18, 1, 0)) AS REAL) * 100 / COUNT(T1.Id) FROM badges AS T1 JOIN users AS T2 ON T1.UserId = T2.Id WHERE T1.Name = 'Organizer'	codebase_community
SELECT c.Score FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.CreaionDate = '2010-07-19 19:19:56.0'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.CreaionDate = '2010-07-19 19:37:33.0'	codebase_community
SELECT DISTINCT u.Age FROM users u INNER JOIN badges b ON u.Id = b.UserId WHERE TRIM(u.Location) = 'Vienna, Austria'	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T1.Name = 'Supporter' AND T2.Age BETWEEN 19 AND 65	codebase_community
SELECT u.Views FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE u.Reputation = (SELECT MIN(Reputation) FROM users WHERE Reputation IS NOT NULL)	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Sharpie'	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T1.Name = 'Supporter' AND T2.Age > 65	codebase_community
SELECT DisplayName FROM users WHERE Id = 30	codebase_community
SELECT COUNT(Id) FROM users WHERE TRIM(Location) = 'New York'	codebase_community
SELECT COUNT(Id) FROM votes WHERE strftime('%Y', CreationDate) = '2010'	codebase_community
SELECT COUNT(Id) FROM users WHERE Age BETWEEN 19 AND 65	codebase_community
SELECT Id, TRIM(DisplayName) AS DisplayName FROM users ORDER BY Views DESC LIMIT 1	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', CreationDate) = '2010', 1, 0)) AS REAL) / SUM(IIF(STRFTIME('%Y', CreationDate) = '2011', 1, 0)) FROM votes	codebase_community
SELECT p."Tags" FROM "posts" p JOIN "users" u ON p."OwnerUserId" = u."Id" WHERE TRIM(u."DisplayName") = 'John Salvatier'	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Daniel Vassallo'	codebase_community
SELECT COUNT(T1.Id) FROM votes AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.DisplayName = 'Harlan'	codebase_community
SELECT p."Id" AS PostId FROM "posts" p JOIN "users" u ON p."OwnerUserId" = u."Id" WHERE TRIM(u."DisplayName") = 'slashnick' ORDER BY p."AnswerCount" DESC LIMIT 1	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) IN ('Harvey Motulsky', 'Noah Snyder') AND p.ViewCount IS NOT NULL ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Matt Parker' AND T1.Id IN (SELECT PostId FROM votes GROUP BY PostId HAVING COUNT(Id) > 4)	codebase_community
SELECT COUNT(T3.Id) FROM users AS T1 JOIN posts AS T2 ON T1.Id = T2.OwnerUserId JOIN comments AS T3 ON T2.Id = T3.PostId WHERE TRIM(T1.DisplayName) = 'Neil McGuigan' AND T3.Score < 60	codebase_community
SELECT p.Tags FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Mark Meckes' AND p.CommentCount = 0	codebase_community
SELECT DISTINCT TRIM(u.DisplayName) AS DisplayName FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'Organizer'	codebase_community
SELECT CAST(COUNT(CASE WHEN p.Tags LIKE '%<r>%' THEN 1 END) AS REAL) * 100 / COUNT(*) AS percentage FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Community'	codebase_community
SELECT (SELECT COALESCE(SUM(p.ViewCount), 0) FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Mornington') - (SELECT COALESCE(SUM(p.ViewCount), 0) FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Amos') AS diff	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Commentator' AND STRFTIME('%Y', Date) = '2014'	codebase_community
SELECT COUNT(Id) FROM posts WHERE CreaionDate BETWEEN '2010-07-21 00:00:00' AND '2010-07-21 23:59:59'	codebase_community
SELECT TRIM("DisplayName") AS DisplayName, "Age" FROM "users" WHERE "Views" = (SELECT MAX("Views") FROM "users")	codebase_community
SELECT "LastEditDate", "LastEditorUserId" FROM "posts" WHERE TRIM("Title") = 'Detecting a given face in a database of facial images'	codebase_community
SELECT COUNT(Id) FROM comments WHERE UserId = 13 AND Score < 60	codebase_community
SELECT p.Title, c.UserDisplayName FROM posts p JOIN comments c ON p.Id = c.PostId WHERE c.Score > 60	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE STRFTIME('%Y', b.Date) = '2011' AND TRIM(u.Location) = 'North Pole'	codebase_community
SELECT u.DisplayName, u.WebsiteUrl FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.FavoriteCount > 150	codebase_community
SELECT ph.Id, p.LastEditDate FROM posts p JOIN postHistory ph ON p.Id = ph.PostId WHERE TRIM(p.Title) = 'What is the best introductory Bayesian statistics textbook?'	codebase_community
SELECT u.LastAccessDate, u.Location FROM users u INNER JOIN badges b ON u.Id = b.UserId WHERE b.Name = 'outliers'	codebase_community
SELECT p2.Title FROM posts p1 JOIN postLinks pl ON p1.Id = pl.PostId JOIN posts p2 ON pl.RelatedPostId = p2.Id WHERE TRIM(p1.Title) = 'How to tell if something happened in a data set which monitors a value over time'	codebase_community
SELECT p.Id as PostId, b.Name FROM users u JOIN posts p ON u.Id = p.OwnerUserId JOIN badges b ON u.Id = b.UserId WHERE TRIM(u.DisplayName) = 'Samuel' AND STRFTIME('%Y', p.CreaionDate) = '2013' AND STRFTIME('%Y', b.Date) = '2013'	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ViewCount IS NOT NULL ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT u.DisplayName, u.Location FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id JOIN users u ON p.OwnerUserId = u.Id WHERE t.TagName = 'hypothesis-testing'	codebase_community
SELECT p2.Title, pl.LinkTypeId FROM posts p1 JOIN postLinks pl ON p1.Id = pl.PostId JOIN posts p2 ON pl.RelatedPostId = p2.Id WHERE p1.Title = 'What are principal component scores?'	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ParentId IS NOT NULL ORDER BY p.Score DESC LIMIT 1	codebase_community
SELECT u.DisplayName, u.WebsiteUrl FROM votes v JOIN users u ON v.UserId = u.Id WHERE v.VoteTypeId = 8 ORDER BY v.BountyAmount DESC LIMIT 1	codebase_community
SELECT Title FROM posts WHERE ViewCount IS NOT NULL AND Title IS NOT NULL ORDER BY ViewCount DESC LIMIT 5	codebase_community
SELECT COUNT(Id) FROM tags WHERE Count BETWEEN 5000 AND 7000	codebase_community
SELECT OwnerUserId FROM posts WHERE FavoriteCount IS NOT NULL ORDER BY FavoriteCount DESC LIMIT 1	codebase_community
SELECT Age FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN votes AS T2 ON T1.Id = T2.PostId WHERE T2.BountyAmount = 50 AND STRFTIME('%Y', T2.CreationDate) = '2011'	codebase_community
SELECT Id FROM users WHERE Age = (SELECT MIN(Age) FROM users WHERE Age IS NOT NULL)	codebase_community
SELECT SUM(Score) FROM posts WHERE LasActivityDate LIKE '2010-07-19%'	codebase_community
SELECT CAST(COUNT(T1.Id) AS REAL) / 12 FROM postLinks T1 JOIN posts T2 ON T1.PostId = T2.Id WHERE STRFTIME('%Y', T1.CreationDate) = '2010' AND T2.AnswerCount <= 2	codebase_community
SELECT p.Id FROM posts p JOIN votes v ON p.Id = v.PostId WHERE v.UserId = 1465 ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT p.Title FROM postLinks pl JOIN posts p ON pl.PostId = p.Id ORDER BY pl.CreationDate ASC LIMIT 1	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM badges b JOIN users u ON b.UserId = u.Id GROUP BY b.UserId, TRIM(u.DisplayName) ORDER BY COUNT(b.Name) DESC LIMIT 1	codebase_community
SELECT MIN(v.CreationDate) AS CreationDate FROM users u JOIN votes v ON u.Id = v.UserId WHERE TRIM(u.DisplayName) = 'chl' AND v.UserId IS NOT NULL	codebase_community
SELECT p.CreaionDate FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE u.Age IS NOT NULL ORDER BY u.Age ASC, p.CreaionDate ASC LIMIT 1	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'Autobiographer' ORDER BY b.Date LIMIT 1	codebase_community
SELECT COUNT(DISTINCT T1.Id) FROM users AS T1 INNER JOIN posts AS T2 ON T1.Id = T2.OwnerUserId WHERE TRIM(T1.Location) = 'United Kingdom' AND T2.FavoriteCount >= 4	codebase_community
SELECT AVG(v."PostId") FROM "votes" v JOIN "users" u ON v."UserId" = u."Id" WHERE u."Age" = (SELECT MAX("Age") FROM "users" WHERE "Age" IS NOT NULL)	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Reputation > 2000 AND Views > 1000	codebase_community
SELECT TRIM("DisplayName") AS DisplayName FROM users WHERE "Age" BETWEEN 19 AND 65	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Jay Stevens' AND STRFTIME('%Y', T1.CreaionDate) = '2010'	codebase_community
SELECT p.Id, p.Title FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Harvey Motulsky' ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT Id, TRIM(Title) AS Title FROM posts ORDER BY Score DESC LIMIT 1	codebase_community
SELECT AVG(T2."Score") FROM "users" AS T1 INNER JOIN "posts" AS T2 ON T2."OwnerUserId" = T1."Id" WHERE TRIM(T1."DisplayName") = 'Stephen Turner'	codebase_community
SELECT DISTINCT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ViewCount > 20000 AND STRFTIME('%Y', p.CreaionDate) = '2011'	codebase_community
SELECT p.OwnerUserId, u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE STRFTIME('%Y', p.CreaionDate) = '2010' ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', T2.CreaionDate) = '2011' AND T1.Reputation > 1000, 1, 0)) AS REAL) * 100 / COUNT(T1.Id) FROM users AS T1 INNER JOIN posts AS T2 ON T1.Id = T2.OwnerUserId	codebase_community
SELECT CAST(COUNT(CASE WHEN Age BETWEEN 13 AND 18 THEN Id END) AS REAL) * 100 / COUNT(Id) AS percentage FROM users	codebase_community
SELECT p.ViewCount, u.DisplayName FROM postHistory ph JOIN posts p ON ph.PostId = p.Id JOIN users u ON ph.UserId = u.Id WHERE TRIM(ph.Text) = 'Computer Game Datasets' ORDER BY ph.CreationDate DESC LIMIT 1	codebase_community
SELECT Id FROM posts WHERE ViewCount > (SELECT AVG(ViewCount) FROM posts)	codebase_community
SELECT COUNT(T2.Id) FROM posts AS T1 INNER JOIN comments AS T2 ON T1.Id = T2.PostId WHERE T1.Score = (SELECT MAX(Score) FROM posts)	codebase_community
SELECT COUNT(Id) FROM posts WHERE ViewCount > 35000 AND CommentCount = 0	codebase_community
SELECT u.DisplayName, u.Location FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 183	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Emmett' ORDER BY b.Date DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Age BETWEEN 19 AND 65 AND UpVotes > 5000	codebase_community
SELECT JULIANDAY(T1.Date) - JULIANDAY(T2.CreationDate) AS "T1.Date - T2.CreationDate" FROM badges AS T1 JOIN users AS T2 ON T1.UserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Zolomon'	codebase_community
SELECT COUNT(p.Id) FROM users u JOIN posts p ON u.Id = p.OwnerUserId JOIN comments c ON p.Id = c.PostId WHERE u.CreationDate = (SELECT MAX(CreationDate) FROM users)	codebase_community
SELECT c.Text, c.UserDisplayName AS DisplayName FROM comments c JOIN posts p ON c.PostId = p.Id WHERE TRIM(p.Title) = 'Analysing wind data with R' ORDER BY c.CreationDate DESC LIMIT 10	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Citizen Patrol'	codebase_community
SELECT COUNT(Id) FROM posts WHERE Tags LIKE '%<careers>%'	codebase_community
SELECT Reputation, Views FROM users WHERE TRIM(DisplayName) = 'Jarrod Dixon'	codebase_community
SELECT (SELECT COUNT(*) FROM comments WHERE PostId = p.Id) AS CommentCount, (SELECT COUNT(*) FROM posts WHERE ParentId = p.Id AND PostTypeId = 2) AS AnswerCount FROM posts p WHERE TRIM(Title) = 'Clustering 1D data' LIMIT 1	codebase_community
SELECT CreationDate FROM users WHERE TRIM(DisplayName) = 'IrishStat'	codebase_community
SELECT COUNT(DISTINCT PostId) AS "COUNT(id)" FROM votes WHERE BountyAmount >= 30	codebase_community
SELECT CAST(SUM(CASE WHEN p.Score > 50 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(p.Id) FROM users u JOIN posts p ON u.Id = p.OwnerUserId WHERE u.Reputation = (SELECT MAX(Reputation) FROM users)	codebase_community
SELECT COUNT(Id) FROM posts WHERE Score < 20	codebase_community
SELECT COUNT(Id) FROM tags WHERE Id < 15 AND Count <= 20	codebase_community
SELECT ExcerptPostId, WikiPostId FROM tags WHERE TagName = 'sample'	codebase_community
SELECT u.Reputation, u.UpVotes FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Text = 'fine, you win :)'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.Title LIKE '%linear regression%'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.ViewCount BETWEEN 100 AND 150 ORDER BY c.Score DESC LIMIT 1	codebase_community
SELECT DISTINCT u.CreationDate, u.Age FROM comments c JOIN users u ON c.UserId = u.Id WHERE u.WebsiteUrl LIKE '%http://%'	codebase_community
SELECT COUNT(T1.Id) FROM comments AS T1 INNER JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T1.Score = 0 AND T2.ViewCount < 5	codebase_community
SELECT COUNT(T1.Id) FROM comments AS T1 INNER JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T2.CommentCount = 1 AND T1.Score = 0	codebase_community
SELECT COUNT(DISTINCT u.Id) FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Score = 0 AND u.Age = 40	codebase_community
SELECT p.Id, c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE TRIM(p.Title) = 'Group differences on a five point Likert item'	codebase_community
SELECT u.UpVotes FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Text = 'R is also lazy evaluated.'	codebase_community
SELECT c.Text FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Harvey Motulsky'	codebase_community
SELECT u.DisplayName FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Score BETWEEN 1 AND 5 AND u.DownVotes = 0	codebase_community
SELECT CAST(COUNT(CASE WHEN u.UpVotes = 0 THEN 1 END) AS REAL) * 100 / COUNT(*) AS per FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Score BETWEEN 5 AND 10	codebase_community
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = '3-D Man'	superhero
SELECT COUNT(T1.hero_id) FROM hero_power AS T1 INNER JOIN superpower AS T2 ON T1.power_id = T2.id WHERE T2.power_name = 'Super Strength'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN hero_power AS T2 ON T1.id = T2.hero_id INNER JOIN superpower AS T3 ON T2.power_id = T3.id WHERE T3.power_name = 'Super Strength' AND T1.height_cm > 200	superhero
SELECT s.full_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id GROUP BY s.id, s.full_name HAVING COUNT(hp.power_id) > 15	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN colour AS T2 ON T1.eye_colour_id = T2.id WHERE T2.colour = 'Blue'	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.skin_colour_id = c.id WHERE s.superhero_name = 'Apocalypse'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id JOIN hero_power AS T3 ON T1.id = T3.hero_id JOIN superpower AS T4 ON T3.power_id = T4.id WHERE T2.colour = 'Blue' AND T4.power_name = 'Agility'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour eye_colour ON s.eye_colour_id = eye_colour.id JOIN colour hair_colour ON s.hair_colour_id = hair_colour.id WHERE eye_colour.colour = 'Blue' AND hair_colour.colour = 'Blond'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT s.superhero_name, s.height_cm, RANK() OVER (ORDER BY s.height_cm DESC) AS HeightRank FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE p.publisher_name = 'Marvel Comics' ORDER BY s.height_cm DESC	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name = 'Sauron'	superhero
SELECT c.colour AS EyeColor, COUNT(s.id) AS Count, RANK() OVER (ORDER BY COUNT(s.id) DESC) AS PopularityRank FROM superhero s JOIN publisher p ON s.publisher_id = p.id JOIN colour c ON s.eye_colour_id = c.id WHERE p.publisher_name = 'Marvel Comics' GROUP BY c.colour, c.id ORDER BY Count DESC	superhero
SELECT AVG(T1.height_cm) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT DISTINCT s.superhero_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE p.publisher_name = 'Marvel Comics' AND sp.power_name = 'Super Strength'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'DC Comics'	superhero
SELECT p.publisher_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id JOIN publisher p ON s.publisher_id = p.id WHERE a.attribute_name = 'Speed' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN colour AS T2 ON T1.eye_colour_id = T2.id INNER JOIN publisher AS T3 ON T1.publisher_id = T3.id WHERE T2.colour = 'Gold' AND T3.publisher_name = 'Marvel Comics'	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name = 'Blue Beetle II'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN colour AS T2 ON T1.hair_colour_id = T2.id WHERE T2.colour = 'Blond'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Intelligence' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.superhero_name = 'Copycat'	superhero
SELECT 1	superhero
SELECT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN gender AS T2 ON T1.gender_id = T2.id JOIN hero_attribute AS T3 ON T1.id = T3.hero_id JOIN attribute AS T4 ON T3.attribute_id = T4.id WHERE T2.gender = 'Female' AND T4.attribute_name = 'Strength' AND T3.attribute_value = 100	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id GROUP BY s.id, s.superhero_name ORDER BY COUNT(hp.power_id) DESC LIMIT 1	superhero
SELECT COUNT(T1.superhero_name) FROM superhero AS T1 JOIN race AS T2 ON T1.race_id = T2.id WHERE T2.race = 'Vampire'	superhero
SELECT 1	superhero
SELECT SUM(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.publisher_name = 'DC Comics' THEN 1 ELSE 0 END) FROM superhero T1 JOIN publisher T2 ON T1.publisher_id = T2.id	superhero
SELECT id FROM publisher WHERE publisher_name = 'Star Trek'	superhero
SELECT AVG(attribute_value) FROM hero_attribute	superhero
SELECT COUNT(id) FROM superhero WHERE full_name IS NULL	superhero
SELECT 1	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Deathlok'	superhero
SELECT AVG(s.weight_kg) FROM superhero s JOIN gender g ON s.gender_id = g.id WHERE g.gender = 'Female'	superhero
SELECT 1	superhero
SELECT 1	superhero
SELECT s.superhero_name FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.height_cm BETWEEN 170 AND 190 AND c.colour = 'No Colour'	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE hp.hero_id = 56	superhero
SELECT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN alignment AS T2 ON T1.alignment_id = T2.id WHERE T2.alignment = 'Bad'	superhero
SELECT 1	superhero
SELECT c.colour FROM superhero s JOIN race r ON s.race_id = r.id JOIN colour c ON s.hair_colour_id = c.id WHERE s.height_cm = 185 AND r.race = 'Human'	superhero
SELECT 1	superhero
SELECT 1	superhero
SELECT s.superhero_name FROM superhero s JOIN gender g ON s.gender_id = g.id WHERE g.gender = 'Male' AND s.weight_kg > (SELECT AVG(weight_kg) * 0.79 FROM superhero)	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id GROUP BY sp.power_name ORDER BY COUNT(*) DESC LIMIT 1	superhero
SELECT ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE s.superhero_name = 'Abomination'	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE hp.hero_id = 1	superhero
SELECT COUNT(T1.hero_id) FROM hero_power AS T1 INNER JOIN superpower AS T2 ON T1.power_id = T2.id WHERE T2.power_name = 'Stealth'	superhero
SELECT s.full_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Strength' ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT CAST(COUNT(*) AS REAL) / SUM(CASE WHEN T2.id = 1 THEN 1 ELSE 0 END) FROM superhero LEFT JOIN colour AS T2 ON superhero.skin_colour_id = T2.id	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'Dark Horse Comics'	superhero
SELECT s.superhero_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE p.publisher_name = 'Dark Horse Comics' AND a.attribute_name = 'Durability' ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.full_name = 'Abraham Sapien'	superhero
SELECT DISTINCT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Flight'	superhero
SELECT s.eye_colour_id, s.hair_colour_id, s.skin_colour_id FROM superhero s JOIN gender g ON s.gender_id = g.id JOIN publisher p ON s.publisher_id = p.id WHERE g.gender = 'Female' AND p.publisher_name = 'Dark Horse Comics'	superhero
SELECT s.superhero_name, p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.hair_colour_id = s.skin_colour_id AND s.hair_colour_id = s.eye_colour_id	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.superhero_name = 'A-Bomb'	superhero
SELECT CAST(COUNT(CASE WHEN T3.colour = 'Blue' THEN T1.id ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN gender AS T2 ON T1.gender_id = T2.id JOIN colour AS T3 ON T1.skin_colour_id = T3.id WHERE T2.gender = 'Female'	superhero
SELECT s.superhero_name, r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.full_name = 'Charles Chandler'	superhero
SELECT g.gender FROM superhero s JOIN gender g ON s.gender_id = g.id WHERE s.superhero_name = 'Agent 13'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Adaptation'	superhero
SELECT COUNT(T1.power_id) FROM hero_power AS T1 INNER JOIN superhero AS T2 ON T1.hero_id = T2.id WHERE T2.superhero_name = 'Amazo'	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.full_name = 'Hunter Zolomon'	superhero
SELECT height_cm FROM superhero JOIN colour ON superhero.eye_colour_id = colour.id WHERE colour.colour = 'Amber'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour eye ON s.eye_colour_id = eye.id JOIN colour hair ON s.hair_colour_id = hair.id WHERE eye.colour = 'Black' AND hair.colour = 'Black'	superhero
SELECT c2.colour FROM superhero s JOIN colour c1 ON s.skin_colour_id = c1.id JOIN colour c2 ON s.eye_colour_id = c2.id WHERE c1.colour = 'Gold'	superhero
SELECT s.full_name FROM superhero s JOIN race r ON s.race_id = r.id WHERE r.race = 'Vampire'	superhero
SELECT s.superhero_name FROM superhero s JOIN alignment a ON s.alignment_id = a.id WHERE a.alignment = 'Neutral'	superhero
SELECT COUNT(T1.hero_id) FROM hero_attribute T1 WHERE T1.attribute_id = 2 AND T1.attribute_value = ( SELECT MAX(attribute_value) FROM hero_attribute WHERE attribute_id = 2 )	superhero
SELECT r.race, a.alignment FROM superhero s JOIN race r ON s.race_id = r.id JOIN alignment a ON s.alignment_id = a.id WHERE s.superhero_name = 'Cameron Hicks'	superhero
SELECT CAST(COUNT(CASE WHEN p.publisher_name = 'Marvel Comics' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(s.id) FROM superhero s JOIN gender g ON s.gender_id = g.id JOIN publisher p ON s.publisher_id = p.id WHERE g.gender = 'Female'	superhero
SELECT CAST(SUM(T1.weight_kg) AS REAL) / COUNT(T1.id) FROM superhero AS T1 JOIN race AS T2 ON T1.race_id = T2.id WHERE T2.race = 'Alien'	superhero
SELECT SUM(CASE WHEN full_name = 'Emil Blonsky' THEN weight_kg ELSE 0 END) - SUM(CASE WHEN full_name = 'Charles Chandler' THEN weight_kg ELSE 0 END) AS CALCULATE FROM superhero	superhero
SELECT CAST(SUM(height_cm) AS REAL) / COUNT(id) FROM superhero	superhero
SELECT sp.power_name FROM superhero sh JOIN hero_power hp ON sh.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sh.superhero_name = 'Abomination'	superhero
SELECT COUNT(*) FROM superhero WHERE race_id = 21 AND gender_id = 1	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Speed' ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 WHERE T1.alignment_id = 3	superhero
SELECT a.attribute_name, ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = '3-D Man'	superhero
SELECT DISTINCT s.superhero_name FROM superhero s JOIN colour eye ON s.eye_colour_id = eye.id JOIN colour hair ON s.hair_colour_id = hair.id WHERE eye.colour = 'Blue' AND hair.colour = 'Brown'	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name IN ('Hawkman', 'Karate Kid', 'Speedy')	superhero
SELECT 1	superhero
SELECT CAST(COUNT(CASE WHEN T2.colour = 'Blue' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id	superhero
SELECT CAST(COUNT(CASE WHEN T2.gender = 'Male' THEN T1.id ELSE NULL END) AS REAL) / COUNT(CASE WHEN T2.gender = 'Female' THEN T1.id ELSE NULL END) FROM superhero AS T1 INNER JOIN gender AS T2 ON T1.gender_id = T2.id	superhero
SELECT superhero_name FROM superhero ORDER BY height_cm DESC LIMIT 1	superhero
SELECT 1	superhero
SELECT superhero_name FROM superhero WHERE id = 294	superhero
SELECT full_name FROM superhero WHERE weight_kg = 0 OR weight_kg IS NULL	superhero
SELECT colour.colour FROM superhero JOIN colour ON superhero.eye_colour_id = colour.id WHERE superhero.full_name = 'Karen Beecher-Duncan'	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.full_name = 'Helen Parr'	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.weight_kg = 108 AND s.height_cm = 188	superhero
SELECT 1	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id JOIN hero_attribute ha ON s.id = ha.hero_id ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT a.alignment, sp.power_name FROM superhero s JOIN alignment a ON s.alignment_id = a.id JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Atom IV'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE c.colour = 'Blue' LIMIT 5	superhero
SELECT AVG(ha.attribute_value) AS "AVG(T1.attribute_value)" FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE s.alignment_id = 3	superhero
SELECT c.colour FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN colour c ON s.skin_colour_id = c.id WHERE ha.attribute_value = 100	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 WHERE T1.alignment_id = 1 AND T1.gender_id = 2	superhero
SELECT DISTINCT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE ha.attribute_value BETWEEN 75 AND 80	superhero
SELECT r.race FROM superhero s JOIN colour c ON s.hair_colour_id = c.id JOIN gender g ON s.gender_id = g.id JOIN race r ON s.race_id = r.id WHERE LOWER(c.colour) = 'blue' AND LOWER(g.gender) = 'male'	superhero
SELECT CAST(COUNT(CASE WHEN T3.gender = 'Female' THEN T1.id ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero T1 JOIN alignment T2 ON T1.alignment_id = T2.id JOIN gender T3 ON T1.gender_id = T3.id WHERE T2.id = 2	superhero
SELECT SUM(CASE WHEN T2.id = 7 THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.id = 1 THEN 1 ELSE 0 END) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id WHERE T1.weight_kg = 0 OR T1.weight_kg IS NULL	superhero
SELECT ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = 'Hulk' AND a.attribute_name = 'Strength'	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Ajax'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.skin_colour_id = T2.id JOIN alignment AS T3 ON T1.alignment_id = T3.id WHERE T2.colour = 'Green' AND T3.alignment = 'Bad'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN gender AS T2 ON T1.gender_id = T2.id INNER JOIN publisher AS T3 ON T1.publisher_id = T3.id WHERE T2.gender = 'Female' AND T3.publisher_name = 'Marvel Comics'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Wind Control' ORDER BY s.superhero_name	superhero
SELECT g.gender FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id JOIN gender g ON s.gender_id = g.id WHERE sp.power_name = 'Phoenix Force'	superhero
SELECT s.superhero_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE p.publisher_name = 'DC Comics' ORDER BY s.weight_kg DESC LIMIT 1	superhero
SELECT AVG(s.height_cm) FROM superhero s JOIN race r ON s.race_id = r.id JOIN publisher p ON s.publisher_id = p.id WHERE r.race != 'Human' AND p.publisher_name = 'Dark Horse Comics'	superhero
SELECT COUNT(T3.superhero_name) FROM superhero AS T3 JOIN hero_attribute AS T2 ON T3.id = T2.hero_id JOIN attribute AS T1 ON T2.attribute_id = T1.id WHERE T1.attribute_name = 'Speed' AND T2.attribute_value = 100	superhero
SELECT SUM(CASE WHEN T2.publisher_name = 'DC Comics' THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE 0 END) FROM superhero T1 JOIN publisher T2 ON T1.publisher_id = T2.id	superhero
SELECT a.attribute_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = 'Black Panther' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.superhero_name = 'Abomination'	superhero
SELECT superhero_name FROM superhero ORDER BY height_cm DESC LIMIT 1	superhero
SELECT superhero_name FROM superhero WHERE full_name = 'Charles Chandler'	superhero
SELECT CAST(COUNT(CASE WHEN T3.gender = 'Female' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN publisher AS T2 ON T1.publisher_id = T2.id JOIN gender AS T3 ON T1.gender_id = T3.id WHERE T2.publisher_name = 'George Lucas'	superhero
SELECT CAST(COUNT(CASE WHEN T3.alignment = 'Good' THEN T1.id ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN publisher AS T2 ON T1.publisher_id = T2.id JOIN alignment AS T3 ON T1.alignment_id = T3.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT COUNT(id) FROM superhero WHERE full_name LIKE 'John%'	superhero
SELECT hero_id FROM hero_attribute ORDER BY attribute_value ASC LIMIT 1	superhero
SELECT full_name FROM superhero WHERE superhero_name = 'Alien'	superhero
SELECT s.full_name FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.weight_kg < 100 AND c.colour = 'Brown'	superhero
SELECT ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE s.superhero_name = 'Aquababy'	superhero
SELECT s.weight_kg, r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.id = 40	superhero
SELECT AVG(T1.height_cm) FROM superhero AS T1 WHERE T1.alignment_id = 3	superhero
SELECT hp.hero_id FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Intelligence'	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.superhero_name = 'Blackwulf'	superhero
SELECT DISTINCT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.height_cm > (SELECT AVG(height_cm) * 0.8 FROM superhero)	superhero
SELECT d.driverRef FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 20 AND q.q1 IS NOT NULL AND q.q1 != '' ORDER BY CAST(q.q1 AS REAL) DESC LIMIT 5	formula_1
SELECT d.surname FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 19 AND q.q2 IS NOT NULL AND q.q2 != '' ORDER BY CAST(q.q2 AS REAL) ASC LIMIT 1	formula_1
SELECT r.year FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.location = 'Shanghai'	formula_1
SELECT r.url FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Circuit de Barcelona-Catalunya'	formula_1
SELECT DISTINCT r.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Germany'	formula_1
SELECT cs.position FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE c.name = 'Renault' ORDER BY cs.raceId	formula_1
SELECT COUNT(T3.raceId) FROM races AS T3 JOIN circuits AS T2 ON T3.circuitId = T2.circuitId WHERE T3.year = 2010 AND T2.country NOT IN ('Austria', 'Azerbaijan', 'Belgium', 'France', 'Germany', 'Hungary', 'Italy', 'Monaco', 'Netherlands', 'Portugal', 'Russia', 'Spain', 'Sweden', 'Switzerland', 'Turkey', 'UK', 'Bahrain', 'China', 'India', 'Japan', 'Korea', 'Malaysia', 'Singapore', 'UAE')	formula_1
SELECT r.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Spain'	formula_1
SELECT DISTINCT c.lat, c.lng FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE r.name = 'Australian Grand Prix'	formula_1
SELECT r.url FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Sepang International Circuit'	formula_1
SELECT r.time FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Sepang International Circuit'	formula_1
SELECT DISTINCT c.lat, c.lng FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.name = 'Abu Dhabi Grand Prix'	formula_1
SELECT c.nationality FROM constructorResults cr JOIN constructors c ON cr.constructorId = c.constructorId WHERE cr.raceId = 24 AND cr.points = 1	formula_1
SELECT q1 FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE d.forename = 'Bruno' AND d.surname = 'Senna' AND q.raceId = 354	formula_1
SELECT d.nationality FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 355 AND q.q2 LIKE '1:40.%' ORDER BY q.q2 ASC LIMIT 1	formula_1
SELECT number FROM qualifying WHERE raceId = 903 AND q3 LIKE '1:54%'	formula_1
SELECT COUNT(T3.driverId) FROM races AS T1 INNER JOIN results AS T3 ON T1.raceId = T3.raceId WHERE T1.name = 'Bahrain Grand Prix' AND T1.year = 2007 AND T3.time IS NULL	formula_1
SELECT s.url FROM races r JOIN seasons s ON r.year = s.year WHERE r.raceId = 901	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '2015-11-29' AND T2.time IS NOT NULL	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 592 AND r.time IS NOT NULL ORDER BY d.dob ASC LIMIT 1	formula_1
SELECT DISTINCT d.forename, d.surname, d.url FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId WHERE lt.raceId = 161 AND lt.time LIKE '1:27.%'	formula_1
SELECT d.nationality FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 933 AND r.fastestLapSpeed IS NOT NULL ORDER BY CAST(r.fastestLapSpeed AS REAL) DESC LIMIT 1	formula_1
SELECT DISTINCT c.lat, c.lng FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.name = 'Malaysian Grand Prix'	formula_1
SELECT c.url FROM constructorResults cr JOIN constructors c ON cr.constructorId = c.constructorId WHERE cr.raceId = 9 ORDER BY cr.points DESC LIMIT 1	formula_1
SELECT q.q1 FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE d.forename = 'Lucas' AND d.surname = 'di Grassi' AND q.raceId = 345	formula_1
SELECT d.nationality FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 347 AND q.q2 = '1:15.018'	formula_1
SELECT d.code FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 45 AND q.q3 LIKE '1:33%'	formula_1
SELECT time FROM results WHERE raceId = 743 AND driverId = 360	formula_1
SELECT d.forename, d.surname FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.name = 'San Marino Grand Prix' AND r.year = 2006 AND res.position = 2	formula_1
SELECT s.url FROM races r JOIN seasons s ON r.year = s.year WHERE r.raceId = 901	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '2015-11-29' AND T2.time IS NULL	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 872 AND r.time IS NOT NULL ORDER BY d.dob DESC LIMIT 1	formula_1
SELECT d.forename, d.surname FROM lapTimes l JOIN drivers d ON l.driverId = d.driverId WHERE l.raceId = 348 ORDER BY CAST(l.time AS INTEGER) ASC LIMIT 1	formula_1
SELECT d.nationality FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.fastestLapSpeed IS NOT NULL ORDER BY CAST(r.fastestLapSpeed AS REAL) DESC LIMIT 1	formula_1
SELECT (SUM(IIF(T2.raceId = 853, CAST(T2.fastestLapSpeed AS REAL), 0)) - SUM(IIF(T2.raceId = 854, CAST(T2.fastestLapSpeed AS REAL), 0))) * 100 / SUM(IIF(T2.raceId = 853, CAST(T2.fastestLapSpeed AS REAL), 0)) FROM drivers AS T1 JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Paul' AND T1.surname = 'di Resta' AND T2.raceId IN (853, 854) AND T2.fastestLapSpeed IS NOT NULL AND T2.fastestLapSpeed != ''	formula_1
SELECT CAST(COUNT(CASE WHEN T2.time IS NOT NULL THEN T2.driverId END) AS REAL) * 100 / COUNT(T2.driverId) FROM races AS T1 JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '1983-07-16'	formula_1
SELECT MIN(year) AS year FROM races WHERE name = 'Singapore Grand Prix'	formula_1
SELECT name FROM races WHERE year = 2005 ORDER BY name DESC	formula_1
SELECT name FROM races WHERE STRFTIME('%Y-%m', date) = (SELECT STRFTIME('%Y-%m', MIN(date)) FROM races)	formula_1
SELECT name, date FROM races WHERE year = 1999 ORDER BY round DESC LIMIT 1	formula_1
SELECT year FROM races GROUP BY year ORDER BY COUNT(*) DESC LIMIT 1	formula_1
SELECT name FROM races WHERE year = 2017 AND circuitId NOT IN (SELECT circuitId FROM races WHERE year = 2000)	formula_1
SELECT c.country, c.location FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.name = 'European Grand Prix' ORDER BY r.year ASC LIMIT 1	formula_1
SELECT r.date FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE c.name = 'Brands Hatch' AND r.name = 'British Grand Prix' ORDER BY r.year DESC LIMIT 1	formula_1
SELECT COUNT(T2.circuitId) FROM races AS T1 INNER JOIN circuits AS T2 ON T1.circuitId = T2.circuitId WHERE T1.name = 'British Grand Prix' AND T2.name = 'Silverstone Circuit'	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 351 ORDER BY r.position	formula_1
SELECT d.forename, d.surname, SUM(ds.points) AS points FROM driverStandings ds JOIN drivers d ON ds.driverId = d.driverId GROUP BY ds.driverId, d.forename, d.surname ORDER BY SUM(ds.points) DESC LIMIT 1	formula_1
SELECT d.forename, d.surname, r.points FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 970 ORDER BY r.points DESC LIMIT 3	formula_1
SELECT lt.milliseconds, d.forename, d.surname, r.name FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId JOIN races r ON lt.raceId = r.raceId ORDER BY lt.milliseconds ASC LIMIT 1	formula_1
SELECT AVG(T2.milliseconds) FROM races AS T1 INNER JOIN lapTimes AS T2 ON T1.raceId = T2.raceId INNER JOIN drivers AS T3 ON T2.driverId = T3.driverId WHERE T1.year = 2009 AND T1.name = 'Malaysian Grand Prix' AND T3.forename = 'Lewis' AND T3.surname = 'Hamilton'	formula_1
SELECT CAST(COUNT(CASE WHEN T2.position <> 1 THEN T2.position END) AS REAL) * 100 / COUNT(T2.driverStandingsId) FROM drivers AS T1 JOIN driverStandings AS T2 ON T1.driverId = T2.driverId JOIN races AS T3 ON T2.raceId = T3.raceId WHERE T1.surname = 'Hamilton' AND T3.year >= 2010	formula_1
SELECT d.forename, d.surname, d.nationality, MAX(ds.points) FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId GROUP BY d.driverId, d.forename, d.surname, d.nationality ORDER BY SUM(ds.wins) DESC LIMIT 1	formula_1
SELECT STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', dob), forename, surname FROM drivers WHERE nationality = 'Japanese' ORDER BY dob DESC LIMIT 1	formula_1
SELECT c.name FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE r.year BETWEEN 1990 AND 2000 GROUP BY c.circuitId, c.name HAVING COUNT(*) = 4	formula_1
SELECT circuits.name, circuits.location, races.name FROM circuits JOIN races ON circuits.circuitId = races.circuitId WHERE circuits.country = 'USA' AND races.year = 2006	formula_1
SELECT r.name, c.name, c.location FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE STRFTIME('%Y', r.date) = '2005' AND STRFTIME('%m', r.date) = '09'	formula_1
SELECT r.name FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Alex' AND d.surname = 'Yoong' AND res.position < 20	formula_1
SELECT SUM(T2.wins) FROM drivers AS T1 JOIN driverStandings AS T2 ON T1.driverId = T2.driverId JOIN races AS T3 ON T2.raceId = T3.raceId JOIN circuits AS T4 ON T3.circuitId = T4.circuitId WHERE T1.forename = 'Michael' AND T1.surname = 'Schumacher' AND T4.name = 'Sepang International Circuit'	formula_1
SELECT r.name, r.year FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Michael' AND d.surname = 'Schumacher' AND res.milliseconds IS NOT NULL ORDER BY res.milliseconds ASC LIMIT 1	formula_1
SELECT AVG(T2.points) FROM drivers AS T1 INNER JOIN driverStandings AS T2 ON T1.driverId = T2.driverId INNER JOIN races AS T3 ON T2.raceId = T3.raceId WHERE T1.forename = 'Eddie' AND T1.surname = 'Irvine' AND T3.year = 2000	formula_1
SELECT r.name, res.points FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY r.year ASC LIMIT 1	formula_1
SELECT r.name, c.country FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2017 ORDER BY r.date	formula_1
SELECT r.laps AS lap, ra.name, ra.year, c.location FROM results r JOIN races ra ON r.raceId = ra.raceId JOIN circuits c ON ra.circuitId = c.circuitId ORDER BY r.laps DESC LIMIT 1	formula_1
SELECT CAST(COUNT(CASE WHEN T1.country = 'Germany' THEN T2.circuitId END) AS REAL) * 100 / COUNT(T2.circuitId) FROM circuits AS T1 JOIN races AS T2 ON T1.circuitId = T2.circuitId WHERE T2.name = 'European Grand Prix'	formula_1
SELECT lat, lng FROM circuits WHERE name = 'Silverstone Circuit'	formula_1
SELECT name FROM circuits WHERE name IN ('Silverstone Circuit', 'Hockenheimring', 'Hungaroring') ORDER BY lat DESC LIMIT 1	formula_1
SELECT circuitRef FROM circuits WHERE name = 'Marina Bay Street Circuit'	formula_1
SELECT country FROM circuits ORDER BY alt DESC LIMIT 1	formula_1
SELECT COUNT(driverId) - COUNT(CASE WHEN code IS NOT NULL THEN code END) FROM drivers	formula_1
SELECT nationality FROM drivers ORDER BY dob ASC LIMIT 1	formula_1
SELECT surname FROM drivers WHERE nationality = 'Italian'	formula_1
SELECT url FROM drivers WHERE forename = 'Anthony' AND surname = 'Davidson'	formula_1
SELECT driverRef FROM drivers WHERE forename = 'Lewis' AND surname = 'Hamilton'	formula_1
SELECT c.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2009 AND r.name = 'Spanish Grand Prix'	formula_1
SELECT r.year FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Silverstone Circuit' ORDER BY r.year	formula_1
SELECT url FROM circuits WHERE name = 'Silverstone Circuit'	formula_1
SELECT r.date, r.time FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2010 AND c.name = 'Yas Marina Circuit'	formula_1
SELECT COUNT(circuits.circuitId) FROM races JOIN circuits ON races.circuitId = circuits.circuitId WHERE circuits.country = 'Italy'	formula_1
SELECT r.date FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Circuit de Barcelona-Catalunya' ORDER BY r.date	formula_1
SELECT c.url FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2009 AND r.name = 'Spanish Grand Prix'	formula_1
SELECT MIN(CAST(r.fastestLapTime AS INTEGER)) AS fastestLapTime FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND r.fastestLapTime IS NOT NULL	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.fastestLapSpeed IS NOT NULL ORDER BY CAST(r.fastestLapSpeed AS REAL) DESC LIMIT 1	formula_1
SELECT d.forename, d.surname, d.driverRef FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.name = 'Canadian Grand Prix' AND r.year = 2007 AND res.position = 1	formula_1
SELECT r.name FROM results res JOIN races r ON res.raceId = r.raceId WHERE res.driverId = 1	formula_1
SELECT r.name FROM results res JOIN drivers d ON res.driverId = d.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND res.rank IS NOT NULL ORDER BY res.rank ASC LIMIT 1	formula_1
SELECT MAX(CAST("results"."fastestLapSpeed" AS REAL)) AS fastestLapSpeed FROM "results" JOIN "races" ON "results"."raceId" = "races"."raceId" WHERE "races"."year" = 2009 AND "races"."name" = 'Spanish Grand Prix'	formula_1
SELECT DISTINCT r.year FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY r.year	formula_1
SELECT r.positionOrder FROM drivers d JOIN results r ON d.driverId = r.driverId JOIN races ra ON r.raceId = ra.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND ra.year = 2008 AND ra.name = 'Chinese Grand Prix'	formula_1
SELECT d.forename, d.surname FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.year = 1989 AND r.name = 'Australian Grand Prix' AND res.grid = 4	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN circuits AS T3 ON T1.circuitId = T3.circuitId INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.year = 2008 AND T3.country = 'Australia' AND T2.time IS NOT NULL	formula_1
SELECT r.fastestLapTime AS fastestLap FROM results r JOIN drivers d ON r.driverId = d.driverId JOIN races ra ON r.raceId = ra.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND ra.year = 2008 AND ra.name = 'Australian Grand Prix'	formula_1
SELECT r.time FROM races ra JOIN results r ON ra.raceId = r.raceId WHERE ra.year = 2008 AND ra.name = 'Chinese Grand Prix' AND r.position = 2	formula_1
SELECT 1	formula_1
SELECT COUNT(*) FROM drivers JOIN results ON drivers.driverId = results.driverId JOIN races ON results.raceId = races.raceId WHERE drivers.nationality = 'British' AND races.year = 2008 AND races.name = 'Australian Grand Prix'	formula_1
SELECT COUNT(*) FROM results WHERE raceId = 34 AND time IS NOT NULL	formula_1
SELECT SUM(T2.points) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton'	formula_1
SELECT AVG(CAST(SUBSTR(T2.fastestLapTime, 1, INSTR(T2.fastestLapTime, ':') - 1) AS INTEGER) * 60 + CAST(SUBSTR(T2.fastestLapTime, INSTR(T2.fastestLapTime, ':') + 1) AS REAL)) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton' AND T2.fastestLapTime IS NOT NULL	formula_1
SELECT CAST(SUM(IIF(T1.time IS NOT NULL, 1, 0)) AS REAL) * 100 / COUNT(T1.resultId) FROM results T1 JOIN races T2 ON T1.raceId = T2.raceId WHERE T2.year = 2008 AND T2.name = 'Australian Grand Prix'	formula_1
WITH race_info AS ( SELECT raceId FROM races WHERE year = 2008 AND name = 'Australian Grand Prix' ), champion_time AS ( SELECT CAST(SUBSTR(time, 1, 2) AS REAL) * 3600 + CAST(SUBSTR(time, 4, 2) AS REAL) * 60 + CAST(SUBSTR(time, 7) AS REAL) AS time_seconds FROM results r JOIN race_info ri ON r.raceId = ri.raceId WHERE r.position = 1 AND r.time IS NOT NULL ), last_driver_time AS ( SELECT CAST(SUBSTR(time, 1, 2) AS REAL) * 3600 + CAST(SUBSTR(time, 4, 2) AS REAL) * 60 + CAST(SUBSTR(time, 7) AS REAL) AS time_seconds FROM results r JOIN race_info ri ON r.raceId = ri.raceId WHERE r.position = (SELECT MAX(position) FROM results WHERE raceId = ri.raceId AND time IS NOT NULL) AND r.time IS NOT NULL ), last_driver_incremental AS ( SELECT (SELECT time_seconds FROM last_driver_time) - (SELECT time_seconds FROM champion_time) AS time_seconds ) SELECT (CAST((SELECT time_seconds FROM last_driver_incremental) AS REAL) * 100) / (SELECT time_seconds + (SELECT time_seconds FROM last_driver_incremental) FROM champion_time) AS "(CAST((SELECT time_seconds FROM last_driver_incremental) AS REAL) * 100) / (SELECT time_seconds + (SELECT time_seconds FROM last_driver_incremental) FROM champion_time)"	formula_1
SELECT COUNT(circuitId) FROM circuits WHERE location = 'Adelaide' AND country = 'Australia'	formula_1
SELECT lat, lng FROM circuits WHERE country = 'USA'	formula_1
SELECT COUNT(driverId) FROM drivers WHERE nationality = 'British' AND STRFTIME('%Y', dob) > '1980'	formula_1
SELECT MAX(cs.points) FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE c.nationality = 'British'	formula_1
SELECT c.name FROM constructors c JOIN constructorStandings cs ON c.constructorId = cs.constructorId ORDER BY cs.points DESC LIMIT 1	formula_1
SELECT c.name FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE cs.raceId = 291 AND cs.points = 0	formula_1
SELECT COUNT(T1.raceId) FROM constructorResults AS T1 JOIN constructors AS T2 ON T1.constructorId = T2.constructorId WHERE T2.nationality = 'Japanese' AND T1.points = 0 GROUP BY T1.constructorId HAVING COUNT(T1.raceId) = 2	formula_1
SELECT DISTINCT c.name FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE cs.position = 1	formula_1
SELECT COUNT(DISTINCT T1.constructorId) FROM constructors AS T1 JOIN results AS T2 ON T1.constructorId = T2.constructorId WHERE T1.nationality = 'French' AND T2.laps > 50	formula_1
SELECT CAST(SUM(IIF(T1.time IS NOT NULL, 1, 0)) AS REAL) * 100 / COUNT(T1.raceId) FROM results AS T1 JOIN drivers AS T2 ON T1.driverId = T2.driverId JOIN races AS T3 ON T1.raceId = T3.raceId WHERE T2.nationality = 'Japanese' AND T3.year BETWEEN 2007 AND 2009	formula_1
SELECT r.year, AVG( CAST(SUBSTR(res.time, 1, 2) AS REAL) * 3600 + CAST(SUBSTR(res.time, 4, 2) AS REAL) * 60 + CAST(SUBSTR(res.time, 7, 6) AS REAL) ) AS AVG_time_seconds FROM results res JOIN races r ON res.raceId = r.raceId WHERE r.year < 1975 AND res.positionText = '1' AND res.time IS NOT NULL GROUP BY r.year ORDER BY r.year	formula_1
SELECT DISTINCT d.forename, d.surname FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId WHERE strftime('%Y', d.dob) > '1975' AND ds.position = 2	formula_1
SELECT COUNT(T1.driverId) FROM drivers AS T1 JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.nationality = 'Italian' AND T2.time IS NULL	formula_1
SELECT d.forename, d.surname, r.fastestLapTime FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.fastestLapTime IS NOT NULL ORDER BY r.fastestLapTime ASC LIMIT 1	formula_1
SELECT r.fastestLap FROM driverStandings ds JOIN races ra ON ds.raceId = ra.raceId JOIN results r ON ds.driverId = r.driverId AND ds.raceId = r.raceId WHERE ra.year = 2009 AND ds.position = 1 AND r.fastestLap IS NOT NULL LIMIT 1	formula_1
SELECT AVG(CAST(T1.fastestLapSpeed AS REAL)) AS "AVG(T1.fastestLapSpeed)" FROM results AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId WHERE T2.year = 2009 AND T2.name = 'Spanish Grand Prix'	formula_1
SELECT r.name, r.year FROM results res JOIN races r ON res.raceId = r.raceId WHERE res.milliseconds IS NOT NULL ORDER BY res.milliseconds ASC LIMIT 1	formula_1
SELECT CAST(SUM(IIF(STRFTIME('%Y', T3.dob) < '1985' AND T1.laps > 50, 1, 0)) AS REAL) * 100 / COUNT(*) FROM results AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId JOIN drivers AS T3 ON T1.driverId = T3.driverId WHERE T2.year BETWEEN 2000 AND 2005	formula_1
SELECT COUNT(T1.driverId) FROM drivers AS T1 INNER JOIN lapTimes AS T2 ON T1.driverId = T2.driverId WHERE T1.nationality = 'French' AND CAST(T2.time AS INTEGER) < 120000	formula_1
SELECT code FROM drivers WHERE nationality = 'American'	formula_1
SELECT raceId FROM races WHERE year = 2009	formula_1
SELECT COUNT(driverId) FROM results WHERE raceId = 18	formula_1
SELECT COUNT(*) FROM (SELECT nationality FROM drivers ORDER BY dob DESC LIMIT 3) WHERE nationality = 'Dutch'	formula_1
SELECT driverRef FROM drivers WHERE forename = 'Robert' AND surname = 'Kubica'	formula_1
SELECT COUNT(driverId) FROM drivers WHERE nationality = 'British' AND STRFTIME('%Y', dob) = '1980'	formula_1
SELECT d.driverId FROM drivers d JOIN lapTimes l ON d.driverId = l.driverId WHERE d.nationality = 'German' AND strftime('%Y', d.dob) BETWEEN '1980' AND '1990' GROUP BY d.driverId ORDER BY MIN(CAST(l.time AS INTEGER)) LIMIT 3	formula_1
SELECT driverRef FROM drivers WHERE nationality = 'German' ORDER BY dob ASC LIMIT 1	formula_1
SELECT DISTINCT d.driverId, d.code FROM drivers d JOIN results r ON d.driverId = r.driverId WHERE strftime('%Y', d.dob) = '1971' AND r.fastestLapTime IS NOT NULL	formula_1
SELECT d.driverId FROM drivers d JOIN lapTimes lt ON d.driverId = lt.driverId WHERE d.nationality = 'Spanish' AND strftime('%Y', d.dob) < '1982' GROUP BY d.driverId ORDER BY MAX(CAST(lt.time AS INTEGER)) DESC LIMIT 10	formula_1
SELECT r.year FROM results res JOIN races r ON res.raceId = r.raceId WHERE res.fastestLapTime IS NOT NULL ORDER BY CAST(res.fastestLapTime AS REAL) ASC LIMIT 1	formula_1
SELECT r.year FROM lapTimes l JOIN races r ON l.raceId = r.raceId ORDER BY CAST(l.time AS INTEGER) DESC LIMIT 1	formula_1
SELECT driverId FROM lapTimes WHERE lap = 1 ORDER BY CAST(time AS INTEGER) ASC LIMIT 5	formula_1
SELECT SUM(IIF(time IS NOT NULL, 1, 0)) FROM results WHERE raceId > 50 AND raceId < 100 AND statusId = 2	formula_1
SELECT location, lat, lng FROM circuits WHERE country = 'Austria'	formula_1
SELECT raceId FROM results WHERE time IS NOT NULL GROUP BY raceId ORDER BY COUNT(*) DESC LIMIT 1	formula_1
SELECT d.driverRef, d.nationality, d.dob FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 23 AND q.q2 IS NOT NULL	formula_1
SELECT r.year, r.name, r.date, r.time FROM drivers d JOIN qualifying q ON d.driverId = q.driverId JOIN races r ON q.raceId = r.raceId WHERE d.dob = (SELECT MAX(dob) FROM drivers WHERE dob IS NOT NULL) ORDER BY r.date LIMIT 1	formula_1
SELECT COUNT(T1.driverId) FROM drivers AS T1 JOIN results AS T2 ON T1.driverId = T2.driverId JOIN status AS T3 ON T2.statusId = T3.statusId WHERE T1.nationality = 'American' AND T3.status = 'Puncture'	formula_1
SELECT c.url FROM constructors c JOIN constructorStandings cs ON c.constructorId = cs.constructorId WHERE c.nationality = 'Italian' GROUP BY c.constructorId, c.url ORDER BY SUM(cs.points) DESC LIMIT 1	formula_1
SELECT c.url FROM constructors c JOIN constructorStandings cs ON c.constructorId = cs.constructorId GROUP BY c.constructorId, c.url ORDER BY SUM(cs.wins) DESC LIMIT 1	formula_1
SELECT lt.driverId FROM races r JOIN lapTimes lt ON r.raceId = lt.raceId WHERE r.name = 'French Grand Prix' AND lt.lap = 3 ORDER BY CAST(lt.time AS INTEGER) DESC LIMIT 1	formula_1
SELECT milliseconds FROM lapTimes WHERE lap = 1 ORDER BY milliseconds ASC LIMIT 1	formula_1
SELECT AVG(T1.fastestLapTime) FROM results T1 JOIN races T2 ON T1.raceId = T2.raceId WHERE T2.year = 2006 AND T2.name = 'United States Grand Prix' AND T1.rank < 11	formula_1
SELECT d.forename, d.surname FROM drivers d JOIN pitStops p ON d.driverId = p.driverId WHERE d.nationality = 'German' AND strftime('%Y', d.dob) BETWEEN '1980' AND '1985' GROUP BY d.driverId, d.forename, d.surname ORDER BY AVG(CAST(p.duration AS REAL)) ASC LIMIT 3	formula_1
SELECT r.time FROM races ra JOIN results r ON ra.raceId = r.raceId WHERE ra.year = 2008 AND ra.name = 'Canadian Grand Prix' AND r.position = 1	formula_1
SELECT c.constructorRef, c.url FROM results r JOIN constructors c ON r.constructorId = c.constructorId WHERE r.raceId = 14 AND r.position = 1	formula_1
SELECT forename, surname, dob FROM drivers WHERE nationality = 'Austrian' AND STRFTIME('%Y', dob) BETWEEN '1981' AND '1991'	formula_1
SELECT forename, surname, url, dob FROM drivers WHERE nationality = 'German' AND STRFTIME('%Y', dob) BETWEEN '1971' AND '1985' ORDER BY dob DESC	formula_1
SELECT country, lat, lng FROM circuits WHERE name = 'Hungaroring'	formula_1
SELECT SUM(constructorStandings.points) AS "SUM(T1.points)", constructors.name, constructors.nationality FROM constructorStandings JOIN races ON constructorStandings.raceId = races.raceId JOIN constructors ON constructorStandings.constructorId = constructors.constructorId WHERE races.name = 'Monaco Grand Prix' AND races.year BETWEEN 1980 AND 2010 GROUP BY constructors.constructorId, constructors.name, constructors.nationality ORDER BY SUM(constructorStandings.points) DESC LIMIT 1	formula_1
SELECT AVG(T2.points) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId INNER JOIN races AS T3 ON T2.raceId = T3.raceId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton' AND T3.name LIKE '%Turkish Grand Prix%'	formula_1
SELECT CAST(SUM(CASE WHEN year BETWEEN 2000 AND 2010 THEN 1 ELSE 0 END) AS REAL) / 10 FROM races	formula_1
SELECT nationality FROM drivers GROUP BY nationality ORDER BY COUNT(*) DESC LIMIT 1	formula_1
SELECT SUM(CASE WHEN points = 91 THEN wins ELSE 0 END) FROM driverStandings	formula_1
SELECT r."name" FROM results res JOIN races r ON res."raceId" = r."raceId" WHERE res."milliseconds" IS NOT NULL ORDER BY res."milliseconds" ASC LIMIT 1	formula_1
SELECT c.location FROM races r JOIN circuits c ON r.circuitId = c.circuitId ORDER BY r.date DESC LIMIT 1	formula_1
SELECT d.forename, d.surname FROM qualifying q JOIN races r ON q.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId JOIN drivers d ON q.driverId = d.driverId WHERE r.year = 2008 AND c.name = 'Marina Bay Street Circuit' AND q.q3 IS NOT NULL ORDER BY CAST(q.q3 AS INTEGER) LIMIT 1	formula_1
SELECT d.forename, d.surname, d.nationality, r.name FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.dob = (SELECT MAX(dob) FROM drivers WHERE dob IS NOT NULL) ORDER BY r.date LIMIT 1	formula_1
SELECT COUNT(T1.driverId) FROM results AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId WHERE T2.name = 'Canadian Grand Prix' AND T1.statusId = 3 GROUP BY T1.driverId ORDER BY COUNT(T1.driverId) DESC LIMIT 1	formula_1
SELECT SUM(ds.wins) AS "SUM(T1.wins)", d.forename, d.surname FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId WHERE d.dob = (SELECT MIN(dob) FROM drivers WHERE dob IS NOT NULL) GROUP BY d.forename, d.surname	formula_1
SELECT MAX(CAST("duration" AS INTEGER)) AS duration FROM "pitStops"	formula_1
SELECT "time" FROM "lapTimes" WHERE "milliseconds" IS NOT NULL ORDER BY "milliseconds" ASC LIMIT 1	formula_1
SELECT MAX(CAST(pitStops.duration AS INTEGER)) AS duration FROM pitStops JOIN drivers ON pitStops.driverId = drivers.driverId WHERE drivers.forename = 'Lewis' AND drivers.surname = 'Hamilton'	formula_1
SELECT ps.lap FROM pitStops ps JOIN drivers d ON ps.driverId = d.driverId JOIN races r ON ps.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND r.year = 2011 AND r.name = 'Australian Grand Prix'	formula_1
SELECT CAST(pitStops.duration AS INTEGER) AS duration FROM pitStops JOIN races ON pitStops.raceId = races.raceId WHERE races.year = 2011 AND races.name = 'Australian Grand Prix'	formula_1
SELECT time FROM lapTimes WHERE driverId = 1 ORDER BY milliseconds ASC LIMIT 1	formula_1
SELECT d.forename, d.surname, d.driverId FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId ORDER BY lt.milliseconds ASC LIMIT 1	formula_1
SELECT lt.position FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY CAST(lt.time AS INTEGER) ASC LIMIT 1	formula_1
SELECT MIN(lt.milliseconds) AS lap_record FROM lapTimes lt JOIN races r ON lt.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Austria'	formula_1
SELECT MIN(lt."milliseconds") AS lap_record FROM circuits c JOIN races r ON c."circuitId" = r."circuitId" JOIN lapTimes lt ON r."raceId" = lt."raceId" WHERE c."country" = 'Italy'	formula_1
SELECT 1	formula_1
SELECT 1	formula_1
SELECT DISTINCT c.lat, c.lng FROM lapTimes lt JOIN races r ON lt.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId WHERE lt.time = '1:29.488'	formula_1
SELECT AVG(pitStops.milliseconds) FROM pitStops JOIN drivers ON pitStops.driverId = drivers.driverId WHERE drivers.forename = 'Lewis' AND drivers.surname = 'Hamilton'	formula_1
SELECT CAST(SUM(T1.milliseconds) AS REAL) / COUNT(T1.lap) FROM lapTimes AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId JOIN circuits AS T3 ON T2.circuitId = T3.circuitId WHERE T3.country = 'Italy'	formula_1
SELECT player_api_id FROM Player_Attributes ORDER BY overall_rating DESC LIMIT 1	european_football_2
SELECT player_name FROM Player ORDER BY height DESC LIMIT 1	european_football_2
SELECT preferred_foot FROM Player_Attributes WHERE preferred_foot IS NOT NULL ORDER BY potential ASC LIMIT 1	european_football_2
SELECT COUNT(id) FROM Player_Attributes WHERE overall_rating >= 60 AND overall_rating < 65 AND defensive_work_rate = 'low'	european_football_2
SELECT p.id FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id GROUP BY p.id ORDER BY MAX(pa.crossing) DESC LIMIT 5	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2015/2016' GROUP BY l.id, l.name ORDER BY SUM(m.home_team_goal + m.away_team_goal) DESC LIMIT 1	european_football_2
SELECT t.team_long_name FROM Match m JOIN Team t ON m.home_team_api_id = t.team_api_id WHERE m.season = '2015/2016' AND m.home_team_goal < m.away_team_goal GROUP BY t.team_api_id, t.team_long_name ORDER BY COUNT(*) ASC LIMIT 1	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id GROUP BY p.player_api_id, p.player_name ORDER BY MAX(pa.penalties) DESC LIMIT 10	european_football_2
SELECT t.team_long_name FROM Match m JOIN League l ON m.league_id = l.id JOIN Team t ON m.away_team_api_id = t.team_api_id WHERE l.name = 'Scotland Premier League' AND m.season = '2009/2010' AND m.away_team_goal > m.home_team_goal GROUP BY t.team_long_name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT buildUpPlaySpeed FROM Team_Attributes ORDER BY buildUpPlaySpeed DESC LIMIT 4	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2015/2016' AND m.home_team_goal = m.away_team_goal GROUP BY l.name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT CAST(strftime('%Y', 'now') AS INTEGER) - CAST(substr(p.birthday, 1, 4) AS INTEGER) AS age FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.sprint_speed >= 97 AND CAST(strftime('%Y', CAST(pa.date AS TEXT)) AS INTEGER) >= 2013 AND CAST(strftime('%Y', CAST(pa.date AS TEXT)) AS INTEGER) <= 2015	european_football_2
SELECT l.name, COUNT(m.league_id) as max_count FROM Match m JOIN League l ON m.league_id = l.id GROUP BY l.name ORDER BY max_count DESC LIMIT 1	european_football_2
SELECT SUM(height) / COUNT(id) FROM Player WHERE birthday >= '1990-01-01 00:00:00' AND birthday < '1996-01-01 00:00:00'	european_football_2
SELECT player_api_id FROM Player_Attributes WHERE substr(date, 1, 4) = '2010' AND overall_rating > ( SELECT AVG(overall_rating) FROM Player_Attributes WHERE substr(date, 1, 4) = '2010' ) ORDER BY overall_rating DESC LIMIT 1	european_football_2
SELECT team_fifa_api_id FROM Team_Attributes WHERE buildUpPlaySpeed > 50 AND buildUpPlaySpeed < 60	european_football_2
SELECT t.team_long_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE strftime('%Y', ta.date) = '2012' AND ta.buildUpPlayPassing IS NOT NULL AND ta.buildUpPlayPassing > ( SELECT AVG(ta2.buildUpPlayPassing) FROM Team_Attributes ta2 WHERE strftime('%Y', ta2.date) = '2012' AND ta2.buildUpPlayPassing IS NOT NULL )	european_football_2
SELECT CAST(SUM(CASE WHEN pa.preferred_foot = 'left' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) AS percent FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id WHERE CAST(p.birthday AS INTEGER) BETWEEN 1987 AND 1992	european_football_2
SELECT l.name, SUM(m.home_team_goal) + SUM(m.away_team_goal) FROM Match m JOIN League l ON m.league_id = l.id GROUP BY l.name ORDER BY SUM(m.home_team_goal) + SUM(m.away_team_goal) ASC LIMIT 5	european_football_2
SELECT CAST(SUM(t2.long_shots) AS REAL) / COUNT(t2.`date`) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Ahmed Samir Farag'	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.height > 180 GROUP BY p.player_api_id, p.player_name ORDER BY AVG(pa.heading_accuracy) DESC LIMIT 10	european_football_2
SELECT t.team_long_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.buildUpPlayDribblingClass = 'Normal' AND ta.date LIKE '2014%' AND ta.chanceCreationPassing < ( SELECT AVG(ta2.chanceCreationPassing) FROM Team_Attributes ta2 WHERE ta2.buildUpPlayDribblingClass = 'Normal' AND ta2.date LIKE '2014%' ) ORDER BY ta.chanceCreationPassing DESC	european_football_2
SELECT League.name FROM Match JOIN League ON Match.league_id = League.id WHERE Match.season = '2009/2010' GROUP BY League.name HAVING AVG(Match.home_team_goal) > AVG(Match.away_team_goal)	european_football_2
SELECT team_short_name FROM Team WHERE team_long_name = 'Queens Park Rangers'	european_football_2
SELECT player_name FROM Player WHERE substr(birthday, 1, 7) = '1970-10'	european_football_2
SELECT DISTINCT pa.attacking_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Franco Zennaro'	european_football_2
SELECT DISTINCT ta.buildUpPlayPositioningClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'ADO Den Haag'	european_football_2
SELECT pa.heading_accuracy FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Francois Affolter' AND pa.date = '2014-09-18 00:00:00'	european_football_2
SELECT pa.overall_rating FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Gabriel Tamas' AND strftime('%Y', pa.date) = '2011'	european_football_2
SELECT COUNT(t2.id) FROM Match t2 JOIN League t1 ON t2.league_id = t1.id WHERE t1.name = 'Scotland Premier League' AND t2.season = '2015/2016'	european_football_2
SELECT pa.preferred_foot FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id ORDER BY CAST(p.birthday AS INTEGER) DESC LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.potential = (SELECT MAX(potential) FROM Player_Attributes)	european_football_2
SELECT COUNT(DISTINCT t1.id) FROM Player_Attributes AS t1 JOIN Player AS t2 ON t1.player_api_id = t2.player_api_id WHERE t2.weight < 130 AND t1.preferred_foot = 'left'	european_football_2
SELECT 1	european_football_2
SELECT DISTINCT pa.defensive_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'David Wilson'	european_football_2
SELECT p.birthday FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT League.name FROM League JOIN Country ON League.country_id = Country.id WHERE Country.name = 'Netherlands'	european_football_2
SELECT CAST(SUM(m.home_team_goal) AS REAL) / COUNT(m.id) FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Poland' AND m.season = '2010/2011'	european_football_2
WITH height_extremes AS ( SELECT MAX(height) as max_height, MIN(height) as min_height FROM Player ), max_height_players AS ( SELECT AVG(pa.finishing) as avg_finishing FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id CROSS JOIN height_extremes he WHERE p.height = he.max_height ), min_height_players AS ( SELECT AVG(pa.finishing) as avg_finishing FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id CROSS JOIN height_extremes he WHERE p.height = he.min_height ) SELECT CASE WHEN mhp.avg_finishing >= mnp.avg_finishing THEN 'Max' ELSE 'Min' END as A FROM max_height_players mhp, min_height_players mnp	european_football_2
SELECT player_name FROM Player WHERE height > 180	european_football_2
SELECT COUNT(id) FROM Player WHERE strftime('%Y', birthday) = '1990'	european_football_2
SELECT COUNT(id) FROM Player WHERE player_name LIKE 'Adam%' AND weight > 170	european_football_2
SELECT DISTINCT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.overall_rating > 80 AND strftime('%Y', pa.date) BETWEEN '2008' AND '2010'	european_football_2
SELECT pa.potential FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Aaron Doran' ORDER BY CAST(pa.date AS INTEGER) DESC LIMIT 1	european_football_2
SELECT DISTINCT p.id, p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.preferred_foot = 'left'	european_football_2
SELECT DISTINCT t.team_long_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.buildUpPlaySpeedClass = 'Fast'	european_football_2
SELECT DISTINCT ta.buildUpPlayPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_short_name = 'CLB'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team_Attributes ta JOIN Team t ON ta.team_api_id = t.team_api_id WHERE ta.buildUpPlayPassing > 70	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.height > 170 AND strftime('%Y', t2.date) >= '2010' AND strftime('%Y', t2.date) <= '2015'	european_football_2
SELECT player_name FROM Player ORDER BY height ASC LIMIT 1	european_football_2
SELECT Country.name FROM League JOIN Country ON League.country_id = Country.id WHERE League.name = 'Italy Serie A'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.buildUpPlaySpeed = 31 AND ta.buildUpPlayDribbling = 53 AND ta.buildUpPlayPassing = 32	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player AS t1 JOIN Player_Attributes AS t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Aaron Doran'	european_football_2
SELECT COUNT(t2.id) FROM League AS t1 JOIN Match AS t2 ON t1.id = t2.league_id WHERE t1.name = 'Germany 1. Bundesliga' AND strftime('%Y-%m', t2.date) BETWEEN '2008-08' AND '2008-10'	european_football_2
SELECT T.team_short_name FROM Match M JOIN Team T ON M.home_team_api_id = T.team_api_id WHERE M.home_team_goal = 10	european_football_2
SELECT DISTINCT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.potential = 61 AND pa.balance = ( SELECT MAX(balance) FROM Player_Attributes WHERE potential = 61 )	european_football_2
SELECT CAST(SUM(CASE WHEN t1.player_name = 'Abdou Diallo' THEN t2.ball_control ELSE 0 END) AS REAL) / COUNT(CASE WHEN t1.player_name = 'Abdou Diallo' THEN t2.id ELSE NULL END) - CAST(SUM(CASE WHEN t1.player_name = 'Aaron Appindangoye' THEN t2.ball_control ELSE 0 END) AS REAL) / COUNT(CASE WHEN t1.player_name = 'Aaron Appindangoye' THEN t2.id ELSE NULL END) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name IN ('Abdou Diallo', 'Aaron Appindangoye')	european_football_2
SELECT team_long_name FROM Team WHERE team_short_name = 'GEN'	european_football_2
SELECT player_name FROM Player WHERE player_name IN ('Aaron Lennon', 'Abdelaziz Barrada') ORDER BY CAST(birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT player_name FROM Player ORDER BY height DESC LIMIT 1	european_football_2
SELECT COUNT(player_api_id) FROM Player_Attributes WHERE preferred_foot = 'left' AND attacking_work_rate = 'low'	european_football_2
SELECT Country.name FROM League JOIN Country ON League.country_id = Country.id WHERE League.name = 'Belgium Jupiler League'	european_football_2
SELECT League.name FROM League JOIN Country ON League.country_id = Country.id WHERE Country.name = 'Germany'	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT COUNT(DISTINCT t1.player_name) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE strftime('%Y', t1.birthday) < '1986' AND t2.defensive_work_rate = 'high'	european_football_2
SELECT p.player_name, pa.crossing FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name IN ('Alexis', 'Ariel Borysiuk', 'Arouna Kone') ORDER BY pa.crossing DESC LIMIT 1	european_football_2
SELECT pa.heading_accuracy FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Ariel Borysiuk' ORDER BY CAST(pa.date AS INTEGER) DESC LIMIT 1	european_football_2
SELECT COUNT(DISTINCT t1.id) FROM Player AS t1 JOIN Player_Attributes AS t2 ON t1.player_api_id = t2.player_api_id WHERE t1.height > 180 AND t2.volleys > 70	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.volleys > 70 AND pa.dribbling > 70	european_football_2
SELECT COUNT(t2.id) FROM Match t2 JOIN Country t1 ON t2.country_id = t1.id WHERE t1.name = 'Belgium' AND t2.season = '2008/2009'	european_football_2
SELECT pa.long_passing FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id ORDER BY CAST(p.birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT COUNT(t2.id) FROM Match t2 JOIN League t3 ON t2.league_id = t3.id WHERE t3.name = 'Belgium Jupiler League' AND SUBSTR(t2.date, 1, 7) = '2009-04'	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2008/2009' GROUP BY l.name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT SUM(t2.overall_rating) / COUNT(t1.id) FROM Player AS t1 INNER JOIN Player_Attributes AS t2 ON t1.player_api_id = t2.player_api_id WHERE strftime('%Y', t1.birthday) < '1986'	european_football_2
SELECT (SUM(CASE WHEN t1.player_name = 'Ariel Borysiuk' THEN t2.overall_rating ELSE 0 END) * 1.0 - SUM(CASE WHEN t1.player_name = 'Paulin Puel' THEN t2.overall_rating ELSE 0 END)) * 100 / SUM(CASE WHEN t1.player_name = 'Paulin Puel' THEN t2.overall_rating ELSE 0 END) AS percentage_difference FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name IN ('Ariel Borysiuk', 'Paulin Puel')	european_football_2
SELECT CAST(SUM(t2.buildUpPlaySpeed) AS REAL) / COUNT(t2.id) FROM Team AS t1 JOIN Team_Attributes AS t2 ON t1.team_api_id = t2.team_api_id WHERE t1.team_long_name = 'Heart of Midlothian'	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Pietro Marino'	european_football_2
SELECT SUM(pa.crossing) FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Aaron Lennox'	european_football_2
SELECT ta.chanceCreationPassing, ta.chanceCreationPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Ajax' ORDER BY ta.chanceCreationPassing DESC LIMIT 1	european_football_2
SELECT pa.preferred_foot FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Abdou Diallo' LIMIT 1	european_football_2
SELECT MAX(t2.overall_rating) FROM Player AS t1 JOIN Player_Attributes AS t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE t1.player_name = 'Dorlan Pabon'	european_football_2
SELECT CAST(SUM(m.away_team_goal) AS REAL) / COUNT(m.id) FROM Match m JOIN Team t ON m.away_team_api_id = t.team_api_id JOIN Country c ON m.country_id = c.id WHERE t.team_long_name = 'Parma' AND c.name = 'Italy'	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.overall_rating = 77 AND pa.date LIKE '2016-06-23%' ORDER BY p.birthday ASC LIMIT 1	european_football_2
SELECT pa.overall_rating FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Aaron Mooy' AND pa.date LIKE '2016-02-04%'	european_football_2
SELECT pa.potential FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Francesco Parravicini' AND pa.date = '2010-08-30 00:00:00'	european_football_2
SELECT pa.attacking_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Francesco Migliore' AND pa.date LIKE '2015-05-01%'	european_football_2
SELECT pa.defensive_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Kevin Berigaud' AND pa.date = '2013-02-22 00:00:00'	european_football_2
SELECT pa.date FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id WHERE p.player_name = 'Kevin Constant' ORDER BY pa.crossing DESC, CAST(pa.date AS INTEGER) ASC LIMIT 1	european_football_2
SELECT ta.buildUpPlaySpeedClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Willem II' AND ta.date = '2011-02-22 00:00:00'	european_football_2
SELECT ta.buildUpPlayDribblingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_short_name = 'LEI' AND ta.date = '2015-09-10 00:00:00'	european_football_2
SELECT ta.buildUpPlayPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'FC Lorient' AND ta.date LIKE '2010-02-22%'	european_football_2
SELECT ta.chanceCreationPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'PEC Zwolle' AND ta.date = '2013-09-20 00:00:00'	european_football_2
SELECT ta.chanceCreationCrossingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Hull City' AND ta.date = '2010-02-22 00:00:00'	european_football_2
SELECT ta.chanceCreationShootingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Hannover 96' AND ta.date LIKE '2015-09-10%'	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Marko Arnautovic' AND SUBSTR(t2.date, 1, 10) BETWEEN '2007-02-22' AND '2016-04-21'	european_football_2
SELECT CAST((ld.overall_rating - jb.overall_rating) AS REAL) * 100 / ld.overall_rating AS LvsJ_percent FROM (SELECT pa.overall_rating FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Landon Donovan' AND DATE(pa.date) = '2013-07-12') ld, (SELECT pa.overall_rating FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Jordan Bowery' AND DATE(pa.date) = '2013-07-12') jb	european_football_2
SELECT player_name FROM Player WHERE height = (SELECT MAX(height) FROM Player)	european_football_2
SELECT player_api_id FROM Player ORDER BY weight DESC LIMIT 10	european_football_2
SELECT DISTINCT player_name FROM Player WHERE (strftime('%Y', 'now') - strftime('%Y', birthday)) - (strftime('%m-%d', 'now') < strftime('%m-%d', birthday)) >= 35	european_football_2
SELECT SUM(t2.home_team_goal) FROM Player t1 JOIN Match t2 ON t1.player_api_id = t2.away_player_9 WHERE t1.player_name = 'Aaron Lennon'	european_football_2
SELECT SUM(m.away_team_goal) FROM Match m JOIN Player p ON p.player_api_id IN (m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11) WHERE p.player_name IN ('Daan Smith', 'Filipe Ferreira')	european_football_2
SELECT SUM(m.home_team_goal) FROM Match m LEFT JOIN Player p1 ON m.home_player_1 = p1.player_api_id LEFT JOIN Player p2 ON m.home_player_2 = p2.player_api_id LEFT JOIN Player p3 ON m.home_player_3 = p3.player_api_id LEFT JOIN Player p4 ON m.home_player_4 = p4.player_api_id LEFT JOIN Player p5 ON m.home_player_5 = p5.player_api_id LEFT JOIN Player p6 ON m.home_player_6 = p6.player_api_id LEFT JOIN Player p7 ON m.home_player_7 = p7.player_api_id LEFT JOIN Player p8 ON m.home_player_8 = p8.player_api_id LEFT JOIN Player p9 ON m.home_player_9 = p9.player_api_id LEFT JOIN Player p10 ON m.home_player_10 = p10.player_api_id LEFT JOIN Player p11 ON m.home_player_11 = p11.player_api_id WHERE ((julianday('now') - julianday(p1.birthday)) / 365.25 <= 30 AND p1.birthday IS NOT NULL) OR ((julianday('now') - julianday(p2.birthday)) / 365.25 <= 30 AND p2.birthday IS NOT NULL) OR ((julianday('now') - julianday(p3.birthday)) / 365.25 <= 30 AND p3.birthday IS NOT NULL) OR ((julianday('now') - julianday(p4.birthday)) / 365.25 <= 30 AND p4.birthday IS NOT NULL) OR ((julianday('now') - julianday(p5.birthday)) / 365.25 <= 30 AND p5.birthday IS NOT NULL) OR ((julianday('now') - julianday(p6.birthday)) / 365.25 <= 30 AND p6.birthday IS NOT NULL) OR ((julianday('now') - julianday(p7.birthday)) / 365.25 <= 30 AND p7.birthday IS NOT NULL) OR ((julianday('now') - julianday(p8.birthday)) / 365.25 <= 30 AND p8.birthday IS NOT NULL) OR ((julianday('now') - julianday(p9.birthday)) / 365.25 <= 30 AND p9.birthday IS NOT NULL) OR ((julianday('now') - julianday(p10.birthday)) / 365.25 <= 30 AND p10.birthday IS NOT NULL) OR ((julianday('now') - julianday(p11.birthday)) / 365.25 <= 30 AND p11.birthday IS NOT NULL)	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.potential = (SELECT MAX(potential) FROM Player_Attributes)	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.attacking_work_rate = 'high'	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.finishing = 1 ORDER BY CAST(p.birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN ( SELECT home_player_1 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_2 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_3 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_4 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_5 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_6 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_7 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_8 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_9 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_10 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT home_player_11 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_1 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_2 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_3 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_4 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_5 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_6 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_7 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_8 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_9 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_10 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' UNION SELECT away_player_11 as player_api_id FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Belgium' ) belgian_players ON p.player_api_id = belgian_players.player_api_id	european_football_2
SELECT DISTINCT c.name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id JOIN Match m ON ( p.player_api_id = m.home_player_1 OR p.player_api_id = m.home_player_2 OR p.player_api_id = m.home_player_3 OR p.player_api_id = m.home_player_4 OR p.player_api_id = m.home_player_5 OR p.player_api_id = m.home_player_6 OR p.player_api_id = m.home_player_7 OR p.player_api_id = m.home_player_8 OR p.player_api_id = m.home_player_9 OR p.player_api_id = m.home_player_10 OR p.player_api_id = m.home_player_11 OR p.player_api_id = m.away_player_1 OR p.player_api_id = m.away_player_2 OR p.player_api_id = m.away_player_3 OR p.player_api_id = m.away_player_4 OR p.player_api_id = m.away_player_5 OR p.player_api_id = m.away_player_6 OR p.player_api_id = m.away_player_7 OR p.player_api_id = m.away_player_8 OR p.player_api_id = m.away_player_9 OR p.player_api_id = m.away_player_10 OR p.player_api_id = m.away_player_11 ) JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE pa.vision > 89 ORDER BY c.name	european_football_2
SELECT c.name FROM Country c JOIN ( SELECT m.country_id, AVG(p.weight) as avg_weight FROM Match m JOIN Player p ON p.player_api_id IN ( m.home_player_1, m.home_player_2, m.home_player_3, m.home_player_4, m.home_player_5, m.home_player_6, m.home_player_7, m.home_player_8, m.home_player_9, m.home_player_10, m.home_player_11, m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11 ) WHERE p.weight IS NOT NULL GROUP BY m.country_id ORDER BY avg_weight DESC LIMIT 1 ) sub ON c.id = sub.country_id	european_football_2
SELECT DISTINCT t.team_long_name FROM Team_Attributes ta JOIN Team t ON ta.team_api_id = t.team_api_id WHERE ta.buildUpPlaySpeedClass = 'Slow'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team_Attributes ta JOIN Team t ON ta.team_api_id = t.team_api_id WHERE ta.chanceCreationPassingClass = 'Safe'	european_football_2
SELECT CAST(SUM(p.height) AS REAL) / COUNT(p.id) FROM Player p JOIN ( SELECT DISTINCT home_player_1 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_2 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_3 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_4 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_5 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_6 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_7 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_8 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_9 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_10 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT home_player_11 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_1 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_2 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_3 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_4 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_5 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_6 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_7 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_8 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_9 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_10 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' UNION SELECT DISTINCT away_player_11 as player_api_id FROM Match m JOIN League l ON m.league_id = l.id JOIN Country c ON l.country_id = c.id WHERE c.name = 'Italy' ) italy_players ON p.player_api_id = italy_players.player_api_id	european_football_2
SELECT player_name FROM Player WHERE height > 180 ORDER BY player_name LIMIT 3	european_football_2
SELECT COUNT(id) FROM Player WHERE player_name LIKE 'Aaron%' AND CAST(SUBSTR(birthday, 1, 4) AS INTEGER) > 1990	european_football_2
SELECT SUM(CASE WHEN t1.id = 6 THEN t1.jumping ELSE 0 END) - SUM(CASE WHEN t1.id = 23 THEN t1.jumping ELSE 0 END) AS "SUM(CASE WHEN t1.id = 6 THEN t1.jumping ELSE 0 END) - SUM(CASE WHEN t1.id = 23 THEN t1.jumping ELSE 0 END)" FROM Player_Attributes t1	european_football_2
SELECT id FROM Player_Attributes WHERE preferred_foot = 'right' ORDER BY potential ASC LIMIT 5	european_football_2
SELECT COUNT(t1.id) FROM Player_Attributes t1 WHERE t1.preferred_foot = 'left' AND t1.crossing = ( SELECT MAX(crossing) FROM Player_Attributes WHERE preferred_foot = 'left' )	european_football_2
SELECT CAST(COUNT(CASE WHEN strength > 80 AND stamina > 80 THEN id ELSE NULL END) AS REAL) * 100 / COUNT(id) FROM Player_Attributes	european_football_2
SELECT Country.name FROM League JOIN Country ON League.country_id = Country.id WHERE League.name = 'Poland Ekstraklasa'	european_football_2
SELECT m.home_team_goal, m.away_team_goal FROM Match m JOIN League l ON m.league_id = l.id WHERE l.name = 'Belgium Jupiler League' AND m.date LIKE '2008-09-24%'	european_football_2
SELECT DISTINCT pa.sprint_speed, pa.agility, pa.acceleration FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Alexis Blin'	european_football_2
SELECT DISTINCT ta.buildUpPlaySpeedClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'KSV Cercle Brugge'	european_football_2
SELECT COUNT(t2.id) FROM Match t2 JOIN League t3 ON t2.league_id = t3.id WHERE t3.name = 'Italy Serie A' AND t2.season = '2015/2016'	european_football_2
SELECT MAX(m.home_team_goal) FROM Match m JOIN League l ON m.league_id = l.id WHERE l.name = 'Netherlands Eredivisie'	european_football_2
SELECT pa.id, pa.finishing, pa.curve FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id ORDER BY p.weight DESC LIMIT 1	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2015/2016' GROUP BY l.name ORDER BY COUNT(m.id) DESC LIMIT 4	european_football_2
SELECT t.team_long_name FROM Match m JOIN Team t ON m.away_team_api_id = t.team_api_id ORDER BY m.away_team_goal DESC LIMIT 1	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT CAST(SUM(CASE WHEN p.height < 180 AND pa.overall_rating > 70 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) AS percent FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id	european_football_2
SELECT CAST(SUM(CASE WHEN Admission = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN Admission = '-' THEN 1 ELSE 0 END) FROM Patient WHERE SEX = 'M'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN STRFTIME('%Y', Birthday) > '1930' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient WHERE SEX = 'F'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN Admission = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient WHERE Birthday BETWEEN '1930-01-01' AND '1940-12-31'	thrombosis_prediction
SELECT SUM(CASE WHEN Admission = '+' THEN 1.0 ELSE 0 END) / SUM(CASE WHEN Admission = '-' THEN 1 ELSE 0 END) FROM Patient WHERE Diagnosis = 'SLE'	thrombosis_prediction
SELECT p.Diagnosis, l.Date FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.ID = 30609 ORDER BY l.Date	thrombosis_prediction
SELECT p.SEX, p.Birthday, e."Examination Date", e.Symptoms FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE p.ID = 163109	thrombosis_prediction
SELECT DISTINCT Patient.ID, Patient.SEX, Patient.Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.LDH > 500	thrombosis_prediction
SELECT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T2.RVVT = '+'	thrombosis_prediction
SELECT Patient.ID, Patient.SEX, Patient.Diagnosis FROM Patient JOIN Examination ON Patient.ID = Examination.ID WHERE Examination.Thrombosis = 2	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p.Birthday) = '1937' AND l."T-CHO" >= 250	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.ALB < 3.5	thrombosis_prediction
SELECT (CAST(SUM(CASE WHEN T1.SEX = 'F' AND (T2.TP < 6.0 OR T2.TP > 8.5) THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*)) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID	thrombosis_prediction
SELECT AVG(T2.`aCL IgG`) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND CAST(strftime('%Y', 'now') AS INTEGER) - CAST(strftime('%Y', T1.Birthday) AS INTEGER) >= 50	thrombosis_prediction
SELECT COUNT(*) FROM Patient WHERE SEX = 'F' AND STRFTIME('%Y', Description) = '1997' AND Admission = '-'	thrombosis_prediction
SELECT MIN(STRFTIME('%Y', `First Date`) - STRFTIME('%Y', Birthday)) FROM Patient	thrombosis_prediction
SELECT COUNT(*) FROM Examination e JOIN Patient p ON e.ID = p.ID WHERE e."Thrombosis" = 1 AND p.SEX = 'F' AND STRFTIME('%Y', e."Examination Date") = '1997'	thrombosis_prediction
SELECT STRFTIME('%Y', MAX(P.Birthday)) - STRFTIME('%Y', MIN(P.Birthday)) FROM Patient P JOIN Laboratory L ON P.ID = L.ID WHERE L.TG IS NOT NULL AND L.TG >= 200	thrombosis_prediction
SELECT e."Symptoms", e."Diagnosis" FROM Examination e JOIN Patient p ON e."ID" = p."ID" WHERE e."Symptoms" IS NOT NULL ORDER BY p."Birthday" DESC LIMIT 1	thrombosis_prediction
SELECT CAST(COUNT(T1.ID) AS REAL) / 12 FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T2.SEX = 'M' AND T1.Date BETWEEN '1998-01-01' AND '1998-12-31'	thrombosis_prediction
SELECT T1.Date, STRFTIME('%Y', T2.`First Date`) - STRFTIME('%Y', T2.Birthday), T2.Birthday FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T2.Diagnosis = 'SJS' ORDER BY T2.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.UA <= 8.0 AND T1.SEX = 'M' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN T2.UA <= 6.5 AND T1.SEX = 'F' THEN 1 ELSE 0 END) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 LEFT JOIN Examination AS T2 ON T1.ID = T2.ID WHERE strftime('%Y', T2."Examination Date") - strftime('%Y', T1."First Date") >= 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE CAST(STRFTIME('%Y', T1.Birthday) AS INTEGER) < 18 AND STRFTIME('%Y', T2."Examination Date") BETWEEN '1990' AND '1993'	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2."T-BIL" >= 2.0	thrombosis_prediction
SELECT Diagnosis FROM Examination WHERE "Examination Date" BETWEEN '1985-01-01' AND '1995-12-31' GROUP BY Diagnosis ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT AVG(1999 - CAST(STRFTIME('%Y', T2.Birthday) AS INTEGER)) FROM Laboratory AS T1 INNER JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.Date BETWEEN '1991-10-01' AND '1991-10-31'	thrombosis_prediction
SELECT STRFTIME('%Y', T2.Date) - STRFTIME('%Y', T1.Birthday), T1.Diagnosis FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID ORDER BY T2.HGB DESC LIMIT 1	thrombosis_prediction
SELECT ANA FROM Examination WHERE ID = 3605340 AND "Examination Date" = '1996-12-02'	thrombosis_prediction
SELECT CASE WHEN `T-CHO` < 250 THEN 'Normal' ELSE 'Abnormal' END FROM Laboratory WHERE ID = 2927464 AND Date = '1995-09-04'	thrombosis_prediction
SELECT SEX FROM Patient WHERE Diagnosis = 'AORTITIS' ORDER BY "First Date" ASC LIMIT 1	thrombosis_prediction
SELECT e."aCL IgA", e."aCL IgG", e."aCL IgM" FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE p.Diagnosis = 'SLE' AND p.Description = '1994-02-19' AND e."Examination Date" = '1993-11-12'	thrombosis_prediction
SELECT p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GPT = 9 AND l.Date = '1992-06-12'	thrombosis_prediction
SELECT STRFTIME('%Y', T2.Date) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.UA = 8.4 AND T2.Date = '1991-10-21'	thrombosis_prediction
SELECT COUNT(*) FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Patient."First Date" = '1991-06-13' AND Patient.Diagnosis = 'SJS' AND STRFTIME('%Y', Laboratory.Date) = '1995'	thrombosis_prediction
SELECT p.Diagnosis FROM Examination e JOIN Patient p ON e.ID = p.ID WHERE e."Examination Date" = '1997-01-27' AND e.Diagnosis = 'SLE'	thrombosis_prediction
SELECT e."Symptoms" FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE p.Birthday = '1959-03-01' AND e."Examination Date" = '1993-09-27'	thrombosis_prediction
SELECT CAST((SUM(CASE WHEN P.Birthday = '1959-02-18' AND L.Date LIKE '1981-11-%' THEN L.`T-CHO` ELSE 0 END) - SUM(CASE WHEN P.Birthday = '1959-02-18' AND L.Date LIKE '1981-12-%' THEN L.`T-CHO` ELSE 0 END)) AS REAL) / SUM(CASE WHEN P.Birthday = '1959-02-18' AND L.Date LIKE '1981-12-%' THEN L.`T-CHO` ELSE 0 END) FROM Patient P JOIN Laboratory L ON P.ID = L.ID WHERE P.Birthday = '1959-02-18' AND (L.Date LIKE '1981-11-%' OR L.Date LIKE '1981-12-%')	thrombosis_prediction
SELECT "ID" FROM "Patient" WHERE UPPER("Diagnosis") LIKE '%BEHCET%' AND date("Description") >= '1997-01-01' AND date("Description") <= '1997-12-31'	thrombosis_prediction
SELECT DISTINCT ID FROM Laboratory WHERE Date BETWEEN '1987-07-06' AND '1996-01-31' AND GPT > 30 AND ALB < 4	thrombosis_prediction
SELECT ID FROM Patient WHERE SEX = 'F' AND STRFTIME('%Y', Birthday) = '1964' AND Admission = '+'	thrombosis_prediction
SELECT COUNT(*) FROM Examination WHERE Thrombosis = 2 AND "ANA Pattern" = 'S' AND "aCL IgM" > (SELECT AVG("aCL IgM") * 1.2 FROM Examination)	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN UA <= 6.5 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Laboratory WHERE "U-PRO" IS NOT NULL AND CAST("U-PRO" AS REAL) > 0 AND CAST("U-PRO" AS REAL) < 30 AND UA IS NOT NULL	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN Diagnosis = 'BEHCET' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Patient WHERE SEX = 'M' AND STRFTIME('%Y', "First Date") = '1981'	thrombosis_prediction
SELECT Patient.ID FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Patient.Admission = '-' AND Laboratory.Date LIKE '1991-10%' AND Laboratory."T-BIL" < 2.0	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND strftime('%Y', T1.Birthday) BETWEEN '1980' AND '1989' AND T2."ANA Pattern" != 'P'	thrombosis_prediction
SELECT p.SEX FROM Patient p JOIN Examination e ON p.ID = e.ID JOIN Laboratory l ON p.ID = l.ID WHERE e.Diagnosis = 'PSS' AND l.CRP = '2+' AND l.CRE = 1 AND l.LDH = 123	thrombosis_prediction
SELECT AVG(T2.ALB) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND T2.PLT > 400 AND T1.Diagnosis = 'SLE'	thrombosis_prediction
SELECT e."Symptoms" FROM Patient p JOIN Examination e ON p."ID" = e."ID" WHERE p."Diagnosis" = 'SLE' AND e."Symptoms" IS NOT NULL GROUP BY e."Symptoms" ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT "First Date", "Diagnosis" FROM Patient WHERE ID = 48473	thrombosis_prediction
SELECT COUNT(ID) FROM Patient WHERE SEX = 'F' AND Diagnosis = 'APS'	thrombosis_prediction
SELECT COUNT(ID) FROM Laboratory WHERE STRFTIME('%Y', "Date") = '1997' AND ("TP" <= 6 OR "TP" >= 8.5)	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN p.Diagnosis = 'SLE' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(e.ID) FROM Examination e JOIN Patient p ON e.ID = p.ID WHERE e.Symptoms LIKE '%thrombocytopenia%'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN SEX = 'F' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Patient WHERE STRFTIME('%Y', Birthday) = '1980' AND Diagnosis = 'RA'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T1.Admission = '-' AND T1.Diagnosis LIKE '%BEHCET%' AND strftime('%Y', T2."Examination Date") BETWEEN '1995' AND '1997'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND T2.WBC < 3.5	thrombosis_prediction
SELECT STRFTIME('%d', T3.`Examination Date`) - STRFTIME('%d', T1.`First Date`) FROM Patient AS T1 INNER JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T1.ID = 821298 ORDER BY T3.`Examination Date` LIMIT 1	thrombosis_prediction
SELECT CASE WHEN (T1.SEX = 'F' AND T2.UA > 6.5) OR (T1.SEX = 'M' AND T2.UA > 8.0) THEN true ELSE false END FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.ID = 57266	thrombosis_prediction
SELECT Date FROM Laboratory WHERE ID = 48473 AND GOT >= 60	thrombosis_prediction
SELECT DISTINCT p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GOT < 60 AND STRFTIME('%Y', l.Date) = '1994'	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.SEX = 'M' AND l.GPT >= 60	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GPT > 60 ORDER BY p.Birthday ASC	thrombosis_prediction
SELECT AVG(LDH) FROM Laboratory WHERE LDH < 500	thrombosis_prediction
SELECT DISTINCT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Laboratory AS T2 JOIN Patient AS T1 ON T1.ID = T2.ID WHERE T2.LDH BETWEEN 600 AND 800	thrombosis_prediction
SELECT DISTINCT p.Admission FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.ALP < 300 AND p.Admission IN ('+', '-')	thrombosis_prediction
SELECT DISTINCT T1.ID, CASE WHEN T2.ALP < 300 THEN 'normal' ELSE 'abNormal' END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Birthday = '1982-04-01'	thrombosis_prediction
SELECT DISTINCT Patient.ID, Patient.SEX, Patient.Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.TP < 6.0	thrombosis_prediction
SELECT l."TP" - 8.5 AS "TP - 8.5" FROM Patient p JOIN Laboratory l ON p."ID" = l."ID" WHERE p."SEX" = 'F' AND l."TP" > 8.5	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.SEX = 'M' AND (l.ALB <= 3.5 OR l.ALB >= 5.5) ORDER BY p.Birthday DESC	thrombosis_prediction
SELECT CASE WHEN T2.ALB >= 3.5 AND T2.ALB <= 5.5 THEN 'normal' ELSE 'abnormal' END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE STRFTIME('%Y', T1.Birthday) = '1982'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.UA > 6.5 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F'	thrombosis_prediction
SELECT AVG(T2.UA) FROM Patient AS T1 JOIN ( SELECT ID, UA, Date, ROW_NUMBER() OVER (PARTITION BY ID ORDER BY Date DESC) AS rn FROM Laboratory WHERE UA IS NOT NULL ) AS T2 ON T1.ID = T2.ID WHERE T2.rn = 1 AND ( (T1.SEX = 'M' AND T2.UA < 8.0) OR (T1.SEX = 'F' AND T2.UA < 6.5) )	thrombosis_prediction
SELECT DISTINCT Patient.ID, Patient.SEX, Patient.Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.UN = 29	thrombosis_prediction
SELECT DISTINCT Patient.ID, Patient.SEX, Patient.Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Patient.Diagnosis = 'RA' AND Laboratory.UN < 30	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.CRE >= 1.5	thrombosis_prediction
SELECT CASE WHEN SUM(CASE WHEN T1.SEX = 'M' THEN 1 ELSE 0 END) > SUM(CASE WHEN T1.SEX = 'F' THEN 1 ELSE 0 END) THEN 'True' ELSE 'False' END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.CRE >= 1.5	thrombosis_prediction
SELECT l."T-BIL", p.ID, p.SEX, p.Birthday FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l."T-BIL" IS NOT NULL ORDER BY l."T-BIL" DESC LIMIT 1	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l."T-BIL" >= 2.0	thrombosis_prediction
SELECT p.ID, l."T-CHO" FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l."T-CHO" = (SELECT MAX("T-CHO") FROM Laboratory) ORDER BY p.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT AVG(STRFTIME('%Y', date('NOW')) - STRFTIME('%Y', T1.Birthday)) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2."T-CHO" >= 250	thrombosis_prediction
SELECT DISTINCT p.ID, p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.TG > 300	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.TG >= 200 AND CAST(STRFTIME('%Y', 'now') AS INTEGER) - CAST(STRFTIME('%Y', T2.Birthday) AS INTEGER) > 50	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Admission = '-' AND l.CPK < 250	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND STRFTIME('%Y', T1.Birthday) BETWEEN '1936' AND '1956' AND T2.CPK >= 250	thrombosis_prediction
SELECT DISTINCT T1.ID, T1.SEX, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.GLU >= 180 AND T2."T-CHO" < 250	thrombosis_prediction
SELECT p.ID, l.GLU FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE strftime('%Y', p.Description) = '1991' AND l.GLU < 180	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.WBC <= 3.5 OR l.WBC >= 9.0 ORDER BY p.SEX, p.Birthday DESC	thrombosis_prediction
SELECT DISTINCT T1.Diagnosis, T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.RBC < 3.5	thrombosis_prediction
SELECT DISTINCT p.ID, p.Admission FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.SEX = 'F' AND CAST(STRFTIME('%Y', 'now') AS INTEGER) - CAST(STRFTIME('%Y', p.Birthday) AS INTEGER) >= 50 AND (l.RBC <= 3.5 OR l.RBC >= 6.0)	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Admission = '-' AND l.HGB < 10	thrombosis_prediction
SELECT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Diagnosis = 'SLE' AND l.HGB > 10 AND l.HGB < 17 ORDER BY p.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.HCT >= 52 GROUP BY T1.ID HAVING COUNT(T1.ID) >= 2	thrombosis_prediction
SELECT AVG(HCT) FROM Laboratory WHERE Date LIKE '1991%' AND HCT < 29	thrombosis_prediction
SELECT SUM(CASE WHEN T2.PLT <= 100 THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.PLT >= 400 THEN 1 ELSE 0 END) FROM Laboratory AS T2 WHERE T2.PLT IS NOT NULL	thrombosis_prediction
SELECT DISTINCT Laboratory.ID FROM Laboratory JOIN Patient ON Laboratory.ID = Patient.ID WHERE STRFTIME('%Y', Laboratory.Date) = '1984' AND CAST(STRFTIME('%Y', 'now') AS INTEGER) - CAST(STRFTIME('%Y', Patient.Birthday) AS INTEGER) < 50 AND Laboratory.PLT BETWEEN 100 AND 400	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.PT >= 14 AND T1.SEX = 'F' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE (strftime('%Y', 'now') - strftime('%Y', T1.Birthday)) > 55 AND T2.PT IS NOT NULL	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p."First Date") > '1992' AND l.PT < 14	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID AND date(T1."Examination Date") = date(T2.Date) WHERE date(T1."Examination Date") > '1997-01-01' AND T2.APTT >= 45	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.APTT > 45 AND T2.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.WBC > 3.5 AND T2.WBC < 9.0 AND (T2.FG <= 150 OR T2.FG >= 450)	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Birthday > '1980-01-01' AND T2.FG IS NOT NULL AND (T2.FG < 150 OR T2.FG > 450)	thrombosis_prediction
SELECT DISTINCT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE (l."U-PRO" GLOB '[0-9]*' AND CAST(l."U-PRO" AS REAL) >= 30) OR l."U-PRO" = '30' OR l."U-PRO" = '100' OR l."U-PRO" = '300' OR l."U-PRO" = '>=1000' OR l."U-PRO" = '>=300' OR l."U-PRO" = '+1(30)' OR l."U-PRO" = '+2(100)'	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Diagnosis = 'SLE' AND l."U-PRO" > 0 AND l."U-PRO" < 30	thrombosis_prediction
SELECT COUNT(DISTINCT ID) FROM Laboratory WHERE IGG >= 2000	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.IGG > 900 AND T1.IGG < 2000 AND T2.Symptoms IS NOT NULL	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.IGA BETWEEN 80 AND 500 ORDER BY l.IGA DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.IGA > 80 AND T2.IGA < 500 AND STRFTIME('%Y', T1.`First Date`) >= '1990'	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.IGM IS NOT NULL AND (l.IGM <= 40 OR l.IGM >= 400) GROUP BY p.Diagnosis ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.CRP = '+' AND T1.Description IS NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.CRE >= 1.5 AND CAST(strftime('%Y', 'now') AS INTEGER) - CAST(strftime('%Y', T2.Birthday) AS INTEGER) < 70	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.RA IN ('-', '+-') AND T1.KCT = '+'	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p.Birthday) >= '1985' AND l.RA IN ('-', '+-')	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE ( (l.RF LIKE '<%' AND SUBSTR(l.RF, 2) <= '20') OR (l.RF NOT LIKE '<%' AND l.RF <= '20') ) AND (strftime('%Y', 'now') - strftime('%Y', p.Birthday)) > 60	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID JOIN Examination AS T3 ON T1.ID = T3.ID WHERE (T2.RF LIKE '<%' AND CAST(SUBSTR(T2.RF, 2) AS REAL) <= 20.0) AND T3.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(DISTINCT p.ID) FROM Patient p JOIN Laboratory l ON p.ID = l.ID JOIN Examination e ON p.ID = e.ID WHERE l.C3 > 35 AND e."ANA Pattern" = 'P'	thrombosis_prediction
SELECT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE l.HCT <= 29 OR l.HCT >= 52 ORDER BY e."aCL IgA" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Diagnosis = 'APS' AND T2.C4 > 10	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND T2.RNP IN ('negative', '0')	thrombosis_prediction
SELECT MAX(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.RNP IS NOT NULL AND Laboratory.RNP NOT IN ('-', '+-')	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE (T1.SM = 'negative' OR T1.SM = '0') AND T2.Thrombosis = 0	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.SM NOT IN ('negative', '0') ORDER BY p.Birthday DESC LIMIT 3	thrombosis_prediction
SELECT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID AND e."Examination Date" = l.Date WHERE e."Examination Date" > '1997-01-01' AND l.SC170 IN ('negative', '0')	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID INNER JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T1.SEX = 'F' AND T2.SC170 IN ('negative', '0') AND T3.Symptoms IS NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.SSA IN ('-', '+-') AND STRFTIME('%Y', T1."First Date") < '2000'	thrombosis_prediction
SELECT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.SSA NOT IN ('negative', '0') ORDER BY p."First Date" LIMIT 1	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.SSB IN ('negative', '0') AND T1.Diagnosis = 'SLE'	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SSB IN ('negative', '0') AND T2.Symptoms IS NOT NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.CENTROMEA IN ('-', '+-') AND T2.SSB IN ('-', '+-')	thrombosis_prediction
SELECT DISTINCT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.DNA IS NOT NULL AND CAST(l.DNA AS INTEGER) >= 8	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE CAST(T2.DNA AS INTEGER) < 8 AND T1.Description IS NULL	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND T2.IGG > 900 AND T2.IGG < 2000	thrombosis_prediction
SELECT COUNT(CASE WHEN T1.Diagnosis LIKE '%SLE%' THEN T1.ID ELSE 0 END) * 1.0 / COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.GOT >= 60	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.GOT < 60	thrombosis_prediction
SELECT MAX(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.GOT >= 60	thrombosis_prediction
SELECT p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GPT < 60 ORDER BY l.GPT DESC LIMIT 3	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.GOT < 60	thrombosis_prediction
SELECT p."First Date" FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.LDH < 500 ORDER BY l.LDH DESC LIMIT 1	thrombosis_prediction
SELECT MAX(P."First Date") AS "First Date" FROM Patient P JOIN Laboratory L ON P.ID = L.ID WHERE L.LDH >= 500	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.ALP >= 300 AND T1.Admission = '+'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '-' AND T2.ALP < 300	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.TP < 6.0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Diagnosis = 'SJS' AND T2.TP > 6.0 AND T2.TP < 8.5	thrombosis_prediction
SELECT Date FROM Laboratory WHERE ALB > 3.5 AND ALB < 5.5 ORDER BY ALB DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.ALB > 3.5 AND T2.ALB < 5.5 AND T2.TP BETWEEN 6.0 AND 8.5	thrombosis_prediction
SELECT e."aCL IgG", e."aCL IgM", e."aCL IgA" FROM Patient p JOIN Laboratory l ON p.ID = l.ID JOIN Examination e ON p.ID = e.ID WHERE p.SEX = 'F' AND l.UA > 6.50 ORDER BY l.UA DESC LIMIT 1	thrombosis_prediction
SELECT MAX(Examination.ANA) AS ANA FROM Examination JOIN Laboratory ON Examination.ID = Laboratory.ID WHERE Laboratory.CRE < 1.5	thrombosis_prediction
SELECT l.ID FROM Laboratory l JOIN Examination e ON l.ID = e.ID WHERE l.CRE < 1.5 ORDER BY e."aCL IgA" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-BIL" >= 2.0 AND T2."ANA Pattern" LIKE '%P%'	thrombosis_prediction
SELECT e."ANA" FROM "Examination" e JOIN "Laboratory" l ON e."ID" = l."ID" WHERE l."T-BIL" < 2.0 ORDER BY l."T-BIL" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-CHO" >= 250 AND T2.KCT = '-'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-CHO" < 250 AND T2."ANA Pattern" = 'P'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.TG < 200 AND T2."Symptoms" IS NOT NULL	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.TG IS NOT NULL AND l.TG < 200 ORDER BY l.TG DESC LIMIT 1	thrombosis_prediction
SELECT DISTINCT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE e.Thrombosis = 0 AND l.CPK < 250	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.CPK < 250 AND (T2.KCT = '+' OR T2.RVVT = '+' OR T2.LAC = '+')	thrombosis_prediction
SELECT MIN(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.GLU IS NOT NULL AND Laboratory.GLU > 180	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T2.GLU < 180 AND T3.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND T2.WBC BETWEEN 3.5 AND 9.0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Diagnosis = 'SLE' AND T2.WBC BETWEEN 3.5 AND 9.0	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE (l.RBC <= 3.5 OR l.RBC >= 6.0) AND p.Admission = '-'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.PLT > 100 AND T1.PLT < 400 AND T2.Diagnosis IS NOT NULL	thrombosis_prediction
SELECT l.PLT FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE p.Diagnosis = 'MCTD' AND l.PLT > 100 AND l.PLT < 400	thrombosis_prediction
SELECT AVG(T2.PT) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.PT IS NOT NULL AND T2.PT < 14	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) AS "COUNT(T1.ID)" FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Thrombosis IN (1, 2) AND T2.PT < 14	thrombosis_prediction
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Angela' AND mem.last_name = 'Sanders'	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.college = 'College of Engineering'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.department = 'Art and Design Department'	student_club
SELECT COUNT(T1.event_id) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Women''s Soccer'	student_club
SELECT m.phone FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE e.event_name = 'Women''s Soccer'	student_club
SELECT COUNT(T1.event_id) FROM event AS T1 JOIN attendance AS T2 ON T1.event_id = T2.link_to_event JOIN member AS T3 ON T2.link_to_member = T3.member_id WHERE T1.event_name = 'Women''s Soccer' AND T3.t_shirt_size = 'Medium'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event GROUP BY e.event_id, e.event_name ORDER BY COUNT(a.link_to_member) DESC LIMIT 1	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'Vice President'	student_club
SELECT e.event_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.first_name = 'Maya' AND m.last_name = 'Mclean'	student_club
SELECT COUNT(T1.event_id) FROM event AS T1 JOIN attendance AS T2 ON T1.event_id = T2.link_to_event JOIN member AS T3 ON T2.link_to_member = T3.member_id WHERE T3.first_name = 'Sacha' AND T3.last_name = 'Harrison' AND STRFTIME('%Y', T1.event_date) = '2019'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event GROUP BY e.event_id, e.event_name, e.type HAVING COUNT(a.link_to_member) > 10 AND e.type != 'Meeting'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event GROUP BY e.event_id, e.event_name HAVING COUNT(a.link_to_member) > 20	student_club
SELECT CAST(COUNT(T2.link_to_event) AS REAL) / COUNT(DISTINCT T2.link_to_event) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.type = 'Meeting' AND STRFTIME('%Y', T1.event_date) = '2020'	student_club
SELECT expense_description FROM expense ORDER BY cost DESC LIMIT 1	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.major_name = 'Environmental Engineering'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE e.event_name = 'Laugh Out Loud'	student_club
SELECT member.last_name FROM member JOIN major ON member.link_to_major = major.major_id WHERE major.major_name = 'Law and Constitutional Studies'	student_club
SELECT z.county FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Sherri' AND m.last_name = 'Ramsey'	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Tyler' AND mem.last_name = 'Hewitt'	student_club
SELECT i.amount FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE m.position = 'Vice President'	student_club
SELECT b.spent FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Food' AND e.event_name = 'September Meeting'	student_club
SELECT z.city, z.state FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.position = 'President'	student_club
SELECT member.first_name, member.last_name FROM member JOIN zip_code ON member.zip = zip_code.zip_code WHERE zip_code.state = 'Illinois'	student_club
SELECT b.spent FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Advertisement' AND e.event_name = 'September Meeting'	student_club
SELECT DISTINCT m.department FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.last_name IN ('Pierce', 'Guidi')	student_club
SELECT SUM(T2.amount) FROM event AS T1 INNER JOIN budget AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'October Speaker'	student_club
SELECT e.approved FROM event ev JOIN budget b ON ev.event_id = b.link_to_event JOIN expense e ON b.budget_id = e.link_to_budget WHERE ev.event_name = 'October Meeting' AND ev.event_date LIKE '2019-10-08%' ORDER BY e.expense_id	student_club
SELECT AVG(T2.cost) FROM member AS T1 INNER JOIN expense AS T2 ON T1.member_id = T2.link_to_member WHERE T1.first_name = 'Elijah' AND T1.last_name = 'Allen' AND (SUBSTR(T2.expense_date, 6, 2) = '09' OR SUBSTR(T2.expense_date, 6, 2) = '10')	student_club
SELECT (SUM(CASE WHEN SUBSTR(event.event_date, 1, 4) = '2019' THEN budget.spent ELSE 0 END) - SUM(CASE WHEN SUBSTR(event.event_date, 1, 4) = '2020' THEN budget.spent ELSE 0 END)) AS num FROM budget JOIN event ON budget.link_to_event = event.event_id	student_club
SELECT location FROM event WHERE event_name = 'Spring Budget Review'	student_club
SELECT cost FROM expense WHERE expense_description = 'Posters' AND expense_date = '2019-09-04'	student_club
SELECT remaining FROM budget WHERE category = 'Food' ORDER BY amount DESC LIMIT 1	student_club
SELECT notes FROM income WHERE source = 'Fundraising' AND date_received = '2019-09-14'	student_club
SELECT COUNT(major_name) FROM major WHERE college = 'College of Humanities and Social Sciences'	student_club
SELECT phone FROM member WHERE first_name = 'Carlo' AND last_name = 'Jacobs'	student_club
SELECT z.county FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Adela' AND m.last_name = 'O''Gallagher'	student_club
SELECT COUNT(T2.event_id) FROM budget AS T1 INNER JOIN event AS T2 ON T1.link_to_event = T2.event_id WHERE T2.event_name = 'November Meeting' AND T1.remaining < 0	student_club
SELECT SUM(T1.amount) FROM budget AS T1 JOIN event AS T2 ON T1.link_to_event = T2.event_id WHERE T2.event_name = 'September Speaker'	student_club
SELECT b.event_status FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id WHERE e.expense_description = 'Post Cards, Posters' AND e.expense_date = '2019-08-20'	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Brent' AND mem.last_name = 'Thomason'	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.major_name = 'Business' AND T1.t_shirt_size = 'Medium'	student_club
SELECT z.type FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Christof' AND m.last_name = 'Nielson'	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'Vice President'	student_club
SELECT z.state FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Sacha' AND m.last_name = 'Harrison'	student_club
SELECT m.department FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'President'	student_club
SELECT i.date_received FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE m.first_name = 'Connor' AND m.last_name = 'Hilton' AND i.source = 'Dues'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN income i ON m.member_id = i.link_to_member WHERE i.source = 'Dues' ORDER BY i.date_received LIMIT 1	student_club
SELECT CAST(SUM(CASE WHEN T2.event_name = 'Yearly Kickoff' THEN T1.amount ELSE 0 END) AS REAL) / SUM(CASE WHEN T2.event_name = 'October Meeting' THEN T1.amount ELSE 0 END) FROM budget T1 JOIN event T2 ON T1.link_to_event = T2.event_id WHERE T1.category = 'Advertisement'	student_club
SELECT CAST(SUM(CASE WHEN T1.category = 'Parking' THEN T1.amount ELSE 0 END) AS REAL) * 100 / SUM(T1.amount) FROM budget AS T1 JOIN event AS T2 ON T1.link_to_event = T2.event_id WHERE T2.event_name = 'November Speaker'	student_club
SELECT SUM(cost) FROM expense WHERE expense_description = 'Pizza'	student_club
SELECT COUNT(DISTINCT city) FROM zip_code WHERE county = 'Orange County' AND state = 'Virginia'	student_club
SELECT DISTINCT department FROM major WHERE college = 'College of Humanities and Social Sciences'	student_club
SELECT z.city, z.county, z.state FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Amy' AND m.last_name = 'Firth'	student_club
SELECT e.expense_description FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id ORDER BY b.remaining ASC LIMIT 1	student_club
SELECT member.member_id FROM member JOIN attendance ON member.member_id = attendance.link_to_member JOIN event ON attendance.link_to_event = event.event_id WHERE event.event_name = 'October Meeting'	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id GROUP BY m.college ORDER BY COUNT(*) DESC LIMIT 1	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.phone = '809-555-3360'	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event ORDER BY b.amount DESC LIMIT 1	student_club
SELECT e.expense_id, e.expense_description FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE m.position = 'Vice President'	student_club
SELECT COUNT(T2.link_to_member) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Women''s Soccer'	student_club
SELECT date_received FROM income JOIN member ON income.link_to_member = member.member_id WHERE member.first_name = 'Casey' AND member.last_name = 'Mason'	student_club
SELECT COUNT(T2.member_id) FROM zip_code AS T1 INNER JOIN member AS T2 ON T1.zip_code = T2.zip WHERE T1.state = 'Maryland'	student_club
SELECT COUNT(T2.link_to_event) FROM member AS T1 INNER JOIN attendance AS T2 ON T1.member_id = T2.link_to_member WHERE T1.phone = '954-555-6240'	student_club
SELECT first_name, last_name FROM member JOIN major ON member.link_to_major = major.major_id WHERE major.department = 'School of Applied Sciences, Technology and Education'	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE e.status = 'Closed' ORDER BY CAST(b.spent AS REAL) / b.amount DESC LIMIT 1	student_club
SELECT COUNT(member_id) FROM member WHERE position = 'President'	student_club
SELECT MAX(spent) FROM budget	student_club
SELECT COUNT(event_id) FROM event WHERE type = 'Meeting' AND STRFTIME('%Y', event_date) = '2020'	student_club
SELECT SUM(spent) FROM budget WHERE category = 'Food'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member GROUP BY m.member_id, m.first_name, m.last_name HAVING COUNT(a.link_to_event) > 7	student_club
SELECT m.first_name, m.last_name FROM member m JOIN major ma ON m.link_to_major = ma.major_id JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE ma.major_name = 'Interior Design' AND e.event_name = 'Community Theater'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE z.city = 'Georgetown' AND z.state = 'South Carolina'	student_club
SELECT i.amount FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE m.first_name = 'Grant' AND m.last_name = 'Gilmour'	student_club
SELECT DISTINCT m.first_name, m.last_name FROM member m JOIN income i ON m.member_id = i.link_to_member WHERE i.amount > 40	student_club
SELECT SUM(T3.cost) FROM event AS T1 INNER JOIN budget AS T2 ON T1.event_id = T2.link_to_event INNER JOIN expense AS T3 ON T2.budget_id = T3.link_to_budget WHERE T1.event_name = 'Yearly Kickoff'	student_club
SELECT DISTINCT m.first_name, m.last_name FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense exp ON b.budget_id = exp.link_to_budget JOIN member m ON exp.link_to_member = m.member_id WHERE e.event_name = 'Yearly Kickoff'	student_club
SELECT m.first_name, m.last_name, i.source FROM income i JOIN member m ON i.link_to_member = m.member_id ORDER BY i.amount DESC LIMIT 1	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget ORDER BY ex.cost ASC LIMIT 1	student_club
SELECT CAST(SUM(CASE WHEN T1.event_name = 'Yearly Kickoff' THEN T3.cost ELSE 0 END) AS REAL) * 100 / SUM(T3.cost) FROM event AS T1 JOIN budget AS T2 ON T1.event_id = T2.link_to_event JOIN expense AS T3 ON T2.budget_id = T3.link_to_budget	student_club
SELECT CAST(SUM(CASE WHEN major_name = 'Finance' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN major_name = 'Physics' THEN 1 ELSE 0 END) AS ratio FROM major	student_club
SELECT source FROM income WHERE date_received BETWEEN '2019-09-01' AND '2019-09-30' GROUP BY source ORDER BY SUM(amount) DESC LIMIT 1	student_club
SELECT first_name, last_name, email FROM member WHERE position = 'Secretary'	student_club
SELECT COUNT(T2.member_id) FROM major AS T1 INNER JOIN member AS T2 ON T1.major_id = T2.link_to_major WHERE T1.major_name = 'Physics Teaching'	student_club
SELECT COUNT(T2.link_to_member) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Community Theater' AND strftime('%Y', T1.event_date) = '2019'	student_club
SELECT COUNT(T3.link_to_event), T1.major_name FROM major AS T1 JOIN member AS T2 ON T1.major_id = T2.link_to_major JOIN attendance AS T3 ON T2.member_id = T3.link_to_member WHERE T2.first_name = 'Luisa' AND T2.last_name = 'Guidi' GROUP BY T1.major_name	student_club
SELECT SUM(spent) / COUNT(spent) FROM budget WHERE category = 'Food' AND event_status = 'Closed'	student_club
SELECT e.event_name FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Advertisement' ORDER BY b.spent DESC LIMIT 1	student_club
SELECT IIF(COUNT(*) > 0, 'YES', 'NO') AS result FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.first_name = 'Maya' AND m.last_name = 'Mclean' AND e.event_name = 'Women''s Soccer'	student_club
SELECT CAST(SUM(CASE WHEN type = 'Community Service' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(type) FROM event WHERE event_date BETWEEN '2019-01-01' AND '2019-12-31'	student_club
SELECT e.cost FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id JOIN event ev ON b.link_to_event = ev.event_id WHERE e.expense_description = 'Posters' AND ev.event_name = 'September Speaker'	student_club
SELECT t_shirt_size FROM member GROUP BY t_shirt_size ORDER BY COUNT(t_shirt_size) DESC LIMIT 1	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE e.status = 'Closed' AND b.remaining < 0 ORDER BY b.remaining ASC LIMIT 1	student_club
SELECT T2.category AS type, SUM(T1.cost) AS "SUM(T3.cost)" FROM expense AS T1 JOIN budget AS T2 ON T1.link_to_budget = T2.budget_id JOIN event AS T3 ON T2.link_to_event = T3.event_id WHERE T3.event_name = 'October Meeting' AND T1.approved = 'true' GROUP BY T2.category	student_club
SELECT T2.category, SUM(T2.amount) FROM event AS T1 JOIN budget AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'April Speaker' GROUP BY T2.category ORDER BY SUM(T2.amount) ASC	student_club
SELECT budget_id FROM budget WHERE category = 'Food' ORDER BY amount DESC LIMIT 1	student_club
SELECT budget_id FROM budget WHERE category = 'Advertisement' ORDER BY amount DESC LIMIT 3	student_club
SELECT SUM(cost) FROM expense WHERE expense_description = 'Parking'	student_club
SELECT SUM(cost) FROM expense WHERE expense_date = '2019-08-20'	student_club
SELECT m.first_name, m.last_name, SUM(e.cost) FROM member m JOIN expense e ON m.member_id = e.link_to_member WHERE m.member_id = 'rec4BLdZHS2Blfp4v' GROUP BY m.first_name, m.last_name	student_club
SELECT DISTINCT e.expense_description FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE m.first_name = 'Sacha' AND m.last_name = 'Harrison'	student_club
SELECT DISTINCT expense.expense_description FROM expense JOIN member ON expense.link_to_member = member.member_id WHERE member.t_shirt_size = 'X-Large'	student_club
SELECT m.zip FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.cost < 50	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Phillip' AND mem.last_name = 'Cullen'	student_club
SELECT m.position FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Business'	student_club
SELECT COUNT(T2.member_id) FROM major AS T1 INNER JOIN member AS T2 ON T1.major_id = T2.link_to_major WHERE T1.major_name = 'Business' AND T2.t_shirt_size = 'Medium'	student_club
SELECT DISTINCT e.type FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.remaining > 30	student_club
SELECT DISTINCT type AS category FROM event WHERE location = 'MU 215'	student_club
SELECT type AS category FROM event WHERE event_date = '2020-03-24T12:00:00'	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'Vice President'	student_club
SELECT CAST(SUM(CASE WHEN T2.major_name = 'Business' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.member_id) FROM member T1 JOIN major T2 ON T1.link_to_major = T2.major_id	student_club
SELECT DISTINCT type AS category FROM event WHERE location = 'MU 215'	student_club
SELECT COUNT(income_id) FROM income WHERE amount = 50	student_club
SELECT COUNT(member_id) FROM member WHERE position = 'Member' AND t_shirt_size = 'X-Large'	student_club
SELECT COUNT(major_id) FROM major WHERE college = 'College of Agriculture and Applied Sciences' AND department = 'School of Applied Sciences, Technology and Education'	student_club
SELECT m.last_name, maj.department, maj.college FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Environmental Engineering'	student_club
SELECT b.category, e.type FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE e.location = 'MU 215' AND e.type = 'Guest Speaker' AND b.spent = 0	student_club
SELECT z.city, z.state FROM member m JOIN major maj ON m.link_to_major = maj.major_id JOIN zip_code z ON m.zip = z.zip_code WHERE m.position = 'Member' AND maj.department = 'Electrical and Computer Engineering Department'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event JOIN member m ON a.link_to_member = m.member_id WHERE e.type = 'Social' AND m.position = 'Vice President' AND e.location = '900 E. Washington St.'	student_club
SELECT m.last_name, m.position FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.expense_description = 'Pizza' AND e.expense_date = '2019-09-10'	student_club
SELECT m.last_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.position = 'Member' AND e.event_name = 'Women''s Soccer'	student_club
SELECT CAST(SUM(CASE WHEN T2.amount = 50 THEN 1.0 ELSE 0 END) AS REAL) * 100 / COUNT(T2.income_id) FROM member T1 JOIN income T2 ON T1.member_id = T2.link_to_member WHERE T1.t_shirt_size = 'Medium'	student_club
SELECT DISTINCT county FROM zip_code WHERE type = 'PO Box'	student_club
SELECT zip_code FROM zip_code WHERE type = 'PO Box' AND county = 'San Juan Municipio' AND state = 'Puerto Rico'	student_club
SELECT event_name FROM event WHERE type = 'Game' AND status = 'Closed' AND event_date BETWEEN '2019-03-15' AND '2020-03-20'	student_club
SELECT DISTINCT a.link_to_event FROM expense e JOIN attendance a ON e.link_to_member = a.link_to_member WHERE e.cost > 50	student_club
SELECT e.link_to_member, a.link_to_event FROM expense e JOIN attendance a ON e.link_to_member = a.link_to_member WHERE e.approved = 'true' AND e.expense_date BETWEEN '2019-01-10' AND '2019-11-19'	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Katy' AND mem.link_to_major = 'rec1N0upiVLy5esTO'	student_club
SELECT member.phone FROM member JOIN major ON member.link_to_major = major.major_id WHERE major.college = 'College of Agriculture and Applied Sciences' AND major.major_name = 'Business'	student_club
SELECT DISTINCT m.email FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.expense_date BETWEEN '2019-09-10' AND '2019-11-19' AND e.cost > 20	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 INNER JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.major_name = 'education' AND T2.college = 'College of Education & Human Services'	student_club
SELECT CAST(SUM(CASE WHEN remaining < 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(budget_id) FROM budget	student_club
SELECT event_id, location, status FROM event WHERE event_date BETWEEN '2019-11-01' AND '2020-03-31'	student_club
SELECT expense_description FROM expense GROUP BY expense_description HAVING AVG(cost) > 50	student_club
SELECT first_name, last_name FROM member WHERE t_shirt_size = 'X-Large'	student_club
SELECT CAST(SUM(CASE WHEN type = 'PO Box' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(zip_code) FROM zip_code	student_club
SELECT e.event_name, e.location FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.remaining > 0	student_club
SELECT e.event_name, e.event_date FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget WHERE ex.expense_description = 'Pizza' AND ex.cost > 50 AND ex.cost < 100	student_club
SELECT DISTINCT m.first_name, m.last_name, maj.major_name FROM member m JOIN expense e ON m.member_id = e.link_to_member JOIN major maj ON m.link_to_major = maj.major_id WHERE e.cost > 100	student_club
SELECT z.city, z.county FROM event e JOIN attendance a ON e.event_id = a.link_to_event JOIN member m ON a.link_to_member = m.member_id JOIN zip_code z ON m.zip = z.zip_code JOIN income i ON m.member_id = i.link_to_member GROUP BY e.event_id, z.city, z.county HAVING COUNT(i.income_id) > 40	student_club
SELECT e.link_to_member AS member_id FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id GROUP BY e.link_to_member HAVING COUNT(DISTINCT b.link_to_event) > 1 ORDER BY SUM(e.cost) DESC LIMIT 1	student_club
SELECT AVG(T1.cost) FROM expense AS T1 JOIN member AS T2 ON T1.link_to_member = T2.member_id WHERE T2.position != 'Member'	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.category = 'Parking' AND b.spent < ( SELECT AVG(spent) FROM budget WHERE category = 'Parking' )	student_club
SELECT SUM(CASE WHEN e.type = 'Meeting' THEN ex.cost ELSE 0 END) * 100.0 / SUM(ex.cost) AS "SUM(CASE WHEN T1.type = 'Meeting' THEN T3.cost ELSE 0 END) * 100 / SUM(T3.cost)" FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget	student_club
SELECT e.link_to_budget AS budget_id FROM expense e WHERE e.expense_description = 'Water, chips, cookies' ORDER BY e.cost DESC LIMIT 1	student_club
SELECT m.first_name, m.last_name FROM member m JOIN expense e ON m.member_id = e.link_to_member GROUP BY m.member_id, m.first_name, m.last_name ORDER BY SUM(e.cost) DESC LIMIT 5	student_club
SELECT DISTINCT m.first_name, m.last_name, m.phone FROM member m JOIN expense e ON m.member_id = e.link_to_member WHERE e.cost > (SELECT AVG(cost) FROM expense)	student_club
SELECT CAST(SUM(CASE WHEN z.state = 'New Jersey' AND m.position = 'Member' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN m.position = 'Member' THEN 1 ELSE 0 END) - CAST(SUM(CASE WHEN z.state = 'Vermont' AND m.position = 'Member' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN m.position = 'Member' THEN 1 ELSE 0 END) AS diff FROM member m JOIN zip_code z ON m.zip = z.zip_code	student_club
SELECT m.major_name, m.department FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Garrett' AND mem.last_name = 'Gerke'	student_club
SELECT m.first_name, m.last_name, e.cost FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.expense_description = 'Water, Veggie tray, supplies'	student_club
SELECT m.last_name, m.phone FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Elementary Education'	student_club
SELECT b.category, b.amount FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE e.event_name = 'January Speaker'	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.category = 'Food'	student_club
SELECT m.first_name, m.last_name, i.amount FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE i.date_received = '2019-09-09'	student_club
SELECT DISTINCT b.category FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id WHERE e.expense_description = 'Posters'	student_club
SELECT m.first_name, m.last_name, maj.college FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE m.position = 'Secretary'	student_club
SELECT SUM(budget.spent) AS "SUM(T1.spent)", event.event_name FROM budget JOIN event ON budget.link_to_event = event.event_id WHERE budget.category = 'Speaker Gifts' GROUP BY event.event_name	student_club
SELECT z.city FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Garrett' AND m.last_name = 'Gerke'	student_club
SELECT m.first_name, m.last_name, m.position FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE z.city = 'Lincolnton' AND z.state = 'North Carolina' AND z.zip_code = 28092	student_club
SELECT COUNT(GasStationID) FROM gasstations WHERE Country = 'CZE' AND Segment = 'Premium'	debit_card_specializing
SELECT CAST(SUM(CASE WHEN Currency = 'EUR' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN Currency = 'CZK' THEN 1 ELSE 0 END) AS ratio FROM customers	debit_card_specializing
SELECT y.CustomerID FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE c.Segment = 'LAM' AND CAST(y.Date AS INTEGER) BETWEEN 201201 AND 201212 ORDER BY y.Consumption ASC LIMIT 1	debit_card_specializing
SELECT AVG(T2.Consumption) / 12 FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'SME' AND T2.Date BETWEEN '201301' AND '201312'	debit_card_specializing
SELECT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Currency = 'CZK' AND CAST(y.Date AS INTEGER) BETWEEN 201101 AND 201112 GROUP BY c.CustomerID ORDER BY SUM(y.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT COUNT(*) FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'KAM' AND y.Consumption < 30000 AND y.Date BETWEEN '201201' AND '201212'	debit_card_specializing
SELECT SUM(IIF(T1.Currency = 'CZK', T2.Consumption, 0)) - SUM(IIF(T1.Currency = 'EUR', T2.Consumption, 0)) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE CAST(T2.Date AS INTEGER) BETWEEN 201201 AND 201212	debit_card_specializing
SELECT SUBSTRING(T2.Date, 1, 4) FROM yearmonth AS T2 JOIN customers AS T3 ON T2.CustomerID = T3.CustomerID WHERE T3.Currency = 'EUR' GROUP BY SUBSTRING(T2.Date, 1, 4) ORDER BY SUM(T2.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT c.Segment FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID GROUP BY c.Segment ORDER BY SUM(y.Consumption) ASC LIMIT 1	debit_card_specializing
SELECT SUBSTR(T2.Date, 1, 4) FROM yearmonth AS T2 JOIN customers AS T1 ON T2.CustomerID = T1.CustomerID WHERE T1.Currency = 'CZK' GROUP BY SUBSTR(T2.Date, 1, 4) ORDER BY SUM(T2.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT SUBSTR(T2.Date, 5, 2) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'SME' AND CAST(T2.Date AS INTEGER) BETWEEN 201301 AND 201312 ORDER BY T2.Consumption DESC LIMIT 1	debit_card_specializing
SELECT CAST(SUM(IIF(T1.Segment = 'SME', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'LAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID), CAST(SUM(IIF(T1.Segment = 'LAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'KAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID), CAST(SUM(IIF(T1.Segment = 'KAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'SME', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) FROM customers T1 JOIN yearmonth T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Currency = 'CZK' AND CAST(T2.Date AS INTEGER) BETWEEN 201301 AND 201312	debit_card_specializing
SELECT CAST((SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2012%', T2.Consumption, 0))) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2012%', T2.Consumption, 0)), CAST(SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)), CAST(SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) FROM customers T1 JOIN yearmonth T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Currency = 'EUR'	debit_card_specializing
SELECT SUM(Consumption) FROM yearmonth WHERE CustomerID = 6 AND Date BETWEEN '201308' AND '201311'	debit_card_specializing
SELECT SUM(IIF(Country = 'CZE', 1, 0)) - SUM(IIF(Country = 'SVK', 1, 0)) FROM gasstations WHERE Segment = 'Discount'	debit_card_specializing
SELECT SUM(IIF(CustomerID = 7, Consumption, 0)) - SUM(IIF(CustomerID = 5, Consumption, 0)) FROM yearmonth WHERE CAST("Date" AS INTEGER) = 201304	debit_card_specializing
SELECT SUM(Currency = 'CZK') - SUM(Currency = 'EUR') FROM customers WHERE Segment = 'SME'	debit_card_specializing
SELECT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'LAM' AND c.Currency = 'EUR' AND y.Date = '201310' ORDER BY y.Consumption DESC LIMIT 1	debit_card_specializing
SELECT T1.CustomerID, SUM(T2.Consumption) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'KAM' GROUP BY T1.CustomerID ORDER BY SUM(T2.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT SUM(T2.Consumption) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'KAM' AND T2.Date = '201305'	debit_card_specializing
SELECT CAST(SUM(IIF(T2.Consumption > 46.73, 1, 0)) AS FLOAT) * 100 / COUNT(T1.CustomerID) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'LAM'	debit_card_specializing
SELECT Country, (SELECT COUNT(GasStationID) FROM gasstations WHERE Segment = 'Value for money') FROM gasstations WHERE Segment = 'Value for money' GROUP BY Country	debit_card_specializing
SELECT CAST(SUM(Currency = 'EUR') AS FLOAT) * 100 / COUNT(CustomerID) FROM customers WHERE Segment = 'KAM'	debit_card_specializing
SELECT CAST(SUM(IIF(Consumption > 528.3, 1, 0)) AS FLOAT) * 100 / COUNT(CustomerID) FROM yearmonth WHERE Date = '201202'	debit_card_specializing
SELECT CAST(SUM(IIF(Segment = 'Premium', 1, 0)) AS FLOAT) * 100 / COUNT(GasStationID) FROM gasstations WHERE Country = 'SVK'	debit_card_specializing
SELECT CustomerID FROM yearmonth WHERE Date = '201309' ORDER BY Consumption DESC LIMIT 1	debit_card_specializing
SELECT c.Segment FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE y.Date = '201309' GROUP BY c.Segment ORDER BY SUM(y.Consumption) ASC LIMIT 1	debit_card_specializing
SELECT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'SME' AND y.Date = '201206' ORDER BY y.Consumption ASC LIMIT 1	debit_card_specializing
SELECT SUM(Consumption) FROM yearmonth WHERE SUBSTR(Date, 1, 4) = '2012' GROUP BY SUBSTR(Date, 5, 2) ORDER BY SUM(Consumption) DESC LIMIT 1	debit_card_specializing
SELECT SUM(y.Consumption) / 12 AS MonthlyConsumption FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT p.Description FROM transactions_1k t JOIN products p ON t.ProductID = p.ProductID WHERE STRFTIME('%Y%m', t.Date) = '201309'	debit_card_specializing
SELECT DISTINCT g.Country FROM yearmonth y JOIN transactions_1k t ON y.CustomerID = t.CustomerID JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE y.Date = '201306'	debit_card_specializing
SELECT DISTINCT g.ChainID FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT DISTINCT p.ProductID, TRIM(p.Description) AS Description FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID JOIN products p ON t.ProductID = p.ProductID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT AVG(Amount) FROM transactions_1k WHERE Date LIKE '2012-01%'	debit_card_specializing
SELECT COUNT(*) FROM ( SELECT DISTINCT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Currency = 'EUR' AND y.Consumption > 1000 ) AS customer_subquery	debit_card_specializing
SELECT TRIM(p.Description) AS Description FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID JOIN products p ON t.ProductID = p.ProductID WHERE g.Country = 'CZE'	debit_card_specializing
SELECT DISTINCT CAST(transactions_1k.Time AS INTEGER) AS Time FROM transactions_1k JOIN gasstations ON transactions_1k.GasStationID = gasstations.GasStationID WHERE gasstations.ChainID = 11	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k AS T1 INNER JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE' AND T1.Price > 1000	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k AS T1 JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE' AND T1.Date > '2012-01-01'	debit_card_specializing
SELECT AVG(T1.Price) FROM transactions_1k AS T1 JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE'	debit_card_specializing
SELECT AVG(t.Price) FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT CustomerID FROM transactions_1k WHERE Date = '2012-08-25' GROUP BY CustomerID ORDER BY SUM(Price) DESC LIMIT 1	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.Date = '2012-08-25' ORDER BY CAST(t.Time AS INTEGER) LIMIT 1	debit_card_specializing
SELECT DISTINCT c.Currency FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Date = '2012-08-24' AND t.Time = '16:25:00'	debit_card_specializing
SELECT c.Segment FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Date = '2012-08-23' AND t.Time = '21:20:00'	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k T1 JOIN customers T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Date = '2012-08-26' AND T2.Currency = 'CZK' AND CAST(T1.Time AS INTEGER) < 1300	debit_card_specializing
SELECT c.Segment FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID ORDER BY t.Date ASC LIMIT 1	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.Date = '2012-08-24' AND t.Time = '12:42:00'	debit_card_specializing
SELECT ProductID FROM transactions_1k WHERE Date = '2012-08-23' AND Time = '21:20:00'	debit_card_specializing
SELECT t.CustomerID, y.Date, y.Consumption FROM transactions_1k t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE t.Price = 124.05 AND t.Date = '2012-08-24' AND y.Date = '201201'	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k T1 JOIN gasstations T2 ON T1.GasStationID = T2.GasStationID WHERE T1.Date = '2012-08-26' AND T1.Time BETWEEN '08:00:00' AND '09:00:00' AND T2.Country = 'CZE'	debit_card_specializing
SELECT c.Currency FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE y.Date = '201306' AND y.Consumption = 214582.17	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.CardID = 667467	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.Date = '2012-08-24' AND t.Price = 548.4	debit_card_specializing
SELECT CAST(SUM(IIF(T2.Currency = 'EUR', 1, 0)) AS FLOAT) * 100 / COUNT(T1.CustomerID) FROM transactions_1k AS T1 JOIN customers AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Date LIKE '2012-08-25%'	debit_card_specializing
SELECT CAST(SUM(IIF(SUBSTR(y.Date, 1, 4) = '2012', y.Consumption, 0)) - SUM(IIF(SUBSTR(y.Date, 1, 4) = '2013', y.Consumption, 0)) AS FLOAT) / SUM(IIF(SUBSTR(y.Date, 1, 4) = '2012', y.Consumption, 0)) FROM transactions_1k t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE t.Price = 634.8 AND t.Date = '2012-08-25'	debit_card_specializing
SELECT GasStationID FROM transactions_1k GROUP BY GasStationID ORDER BY SUM(Amount * Price) DESC LIMIT 1	debit_card_specializing
SELECT (CAST(SUM(IIF(Country = 'SVK' AND Segment = 'Premium', 1, 0)) AS FLOAT) * 100 / SUM(IIF(Country = 'SVK', 1, 0))) FROM gasstations	debit_card_specializing
SELECT SUM(Price), SUM(IIF(strftime('%Y%m', Date) = '201201', Price, 0)) FROM transactions_1k WHERE CustomerID = 38508	debit_card_specializing
SELECT TRIM(p.Description) AS Description FROM transactions_1k t JOIN products p ON t.ProductID = p.ProductID GROUP BY p.ProductID, p.Description ORDER BY SUM(t.Amount) DESC LIMIT 5	debit_card_specializing
SELECT t.CustomerID, SUM(t.Price / t.Amount) AS avg_price_per_item, c.Currency FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Amount > 0 GROUP BY t.CustomerID, c.Currency ORDER BY SUM(t.Price) DESC LIMIT 1	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.ProductID = 2 ORDER BY t.Price DESC LIMIT 1	debit_card_specializing
SELECT DISTINCT y.Consumption FROM transactions_1k t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE t.ProductID = 5 AND (t.Price / t.Amount) > 29.00 AND y.Date = '201208'	debit_card_specializing
