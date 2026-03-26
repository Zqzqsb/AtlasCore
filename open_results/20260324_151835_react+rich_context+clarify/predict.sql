SELECT MAX(CAST("Free Meal Count (K-12)" AS REAL) / CAST("Enrollment (K-12)" AS REAL)) AS "Free Meal Count (K-12) / Enrollment (K-12)" FROM frpm WHERE "County Name" = 'Alameda'	california_schools
SELECT CAST("Free Meal Count (Ages 5-17)" AS REAL) / "Enrollment (Ages 5-17)" AS "Free Meal Count (Ages 5-17) / Enrollment (Ages 5-17)" FROM frpm WHERE "Educational Option Type" = 'Continuation School' AND "Free Meal Count (Ages 5-17)" IS NOT NULL AND "Enrollment (Ages 5-17)" IS NOT NULL AND "Enrollment (Ages 5-17)" > 0 ORDER BY CAST("Free Meal Count (Ages 5-17)" AS REAL) / "Enrollment (Ages 5-17)" ASC LIMIT 3	california_schools
SELECT s.Zip FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 AND f."District Name" = 'Fresno County Office of Education'	california_schools
SELECT s.MailStreet FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) ORDER BY f."FRPM Count (K-12)" DESC LIMIT 1	california_schools
SELECT s.Phone FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 AND f."Charter Funding Type" = 'Directly funded' AND s.OpenDate > '2000-01-01'	california_schools
SELECT COUNT(DISTINCT T2.School) FROM satscores AS T1 JOIN schools AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T1.AvgScrMath > 400 AND T2.Virtual = 'F'	california_schools
SELECT s.School FROM schools s JOIN satscores sat ON s.CDSCode = sat.cds WHERE sat.NumTstTakr > 500 AND s.Magnet = 1	california_schools
SELECT schools.Phone FROM schools JOIN satscores ON CAST(schools.CDSCode AS INTEGER) = CAST(satscores.cds AS INTEGER) ORDER BY satscores.NumGE1500 DESC LIMIT 1	california_schools
SELECT s.NumTstTakr FROM frpm f JOIN satscores s ON CAST(f.CDSCode AS INTEGER) = CAST(s.cds AS INTEGER) ORDER BY f."FRPM Count (K-12)" DESC LIMIT 1	california_schools
SELECT COUNT(T2.`School Code`) FROM satscores AS T1 JOIN frpm AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T1.AvgScrMath > 560 AND T2.`Charter Funding Type` = 'Directly funded'	california_schools
SELECT "FRPM Count (Ages 5-17)" FROM satscores JOIN frpm ON CAST(satscores.cds AS INTEGER) = CAST(frpm.CDSCode AS INTEGER) ORDER BY satscores.AvgScrRead DESC LIMIT 1	california_schools
SELECT CDSCode FROM frpm WHERE ("Enrollment (K-12)" + "Enrollment (Ages 5-17)") > 500	california_schools
SELECT MAX(free_rate) FROM ( SELECT CAST(T1.`Free Meal Count (Ages 5-17)` AS REAL) / T1.`Enrollment (Ages 5-17)` AS free_rate FROM frpm AS T1 JOIN satscores AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.cds AS INTEGER) WHERE CAST(T2.NumGE1500 AS REAL) / T2.NumTstTakr > 0.3 )	california_schools
SELECT s.Phone FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE sat.NumTstTakr > 0 ORDER BY CAST(sat.NumGE1500 AS REAL) / sat.NumTstTakr DESC LIMIT 3	california_schools
SELECT s.NCESSchool FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY f."Enrollment (Ages 5-17)" DESC LIMIT 5	california_schools
SELECT dname AS District FROM satscores WHERE rtype = 'D' ORDER BY AvgScrRead DESC LIMIT 1	california_schools
SELECT COUNT(T1.CDSCode) FROM schools AS T1 JOIN satscores AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.cds AS INTEGER) WHERE T1.County = 'Alameda' AND T1.StatusType = 'Merged' AND T2.NumTstTakr < 100	california_schools
SELECT s.CharterNum, sat.AvgScrWrite, RANK() OVER (ORDER BY sat.AvgScrWrite DESC) AS WritingScoreRank FROM schools s JOIN satscores sat ON s.CDSCode = sat.cds WHERE s.CharterNum IS NOT NULL AND sat.AvgScrWrite > 499 ORDER BY sat.AvgScrWrite DESC	california_schools
SELECT COUNT(T1.CDSCode) FROM schools AS T1 INNER JOIN satscores AS T2 ON T1.CDSCode = T2.cds WHERE T1.County = 'Fresno' AND T1.FundingType = 'Directly funded' AND T2.NumTstTakr <= 250	california_schools
SELECT "schools"."Phone" FROM "satscores" JOIN "schools" ON CAST("satscores"."cds" AS INTEGER) = CAST("schools"."CDSCode" AS INTEGER) ORDER BY "satscores"."AvgScrMath" DESC LIMIT 1	california_schools
SELECT COUNT(T1.`School Name`) FROM frpm AS T1 WHERE T1.`County Name` = 'Amador' AND T1.`Low Grade` = '9' AND T1.`High Grade` = '12'	california_schools
SELECT COUNT(frpm.CDSCode) FROM frpm JOIN schools ON CAST(frpm.CDSCode AS INTEGER) = CAST(schools.CDSCode AS INTEGER) WHERE schools.County = 'Los Angeles' AND frpm."Free Meal Count (K-12)" > 500 AND frpm."FRPM Count (K-12)" < 700	california_schools
SELECT sname FROM satscores WHERE cname = 'Contra Costa' AND sname IS NOT NULL ORDER BY NumTstTakr DESC LIMIT 1	california_schools
SELECT s.School, s.Street FROM frpm f JOIN schools s ON f.CDSCode = s.CDSCode WHERE f."Enrollment (K-12)" - f."Enrollment (Ages 5-17)" > 30	california_schools
SELECT DISTINCT frpm."School Name" FROM frpm JOIN satscores ON CAST(frpm."CDSCode" AS INTEGER) = CAST(satscores.cds AS INTEGER) WHERE (frpm."Free Meal Count (K-12)" / frpm."Enrollment (K-12)") > 0.1 AND satscores.NumGE1500 >= 1	california_schools
SELECT s.sname, sch.FundingType AS "Charter Funding Type" FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE sch.District LIKE '%Riverside%' AND s.AvgScrMath > 400 AND s.rtype = 'S'	california_schools
SELECT f."School Name", s.Street, s.City, s.State, s.Zip FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.City = 'Monterey' AND f."School Type" LIKE '%High%' AND f."FRPM Count (Ages 5-17)" > 800	california_schools
SELECT s.School, sat.AvgScrWrite, s.Phone FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE (s.OpenDate > '1991-12-31') OR (s.ClosedDate < '2000-01-01')	california_schools
WITH locally_funded_diff AS ( SELECT s.School, s.DOCType AS DOC, f."Enrollment (K-12)" - f."Enrollment (Ages 5-17)" AS diff FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.FundingType = 'Locally funded' ) SELECT School, DOC FROM locally_funded_diff WHERE diff > (SELECT AVG(diff) FROM locally_funded_diff)	california_schools
SELECT s.OpenDate FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.GSoffered = 'K-12' ORDER BY f."Enrollment (K-12)" DESC LIMIT 1	california_schools
SELECT DISTINCT s.City FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY f."Enrollment (K-12)" ASC LIMIT 5	california_schools
SELECT CAST(`Free Meal Count (K-12)` AS REAL) / `Enrollment (K-12)` FROM frpm ORDER BY `Enrollment (K-12)` DESC LIMIT 2 OFFSET 9	california_schools
SELECT CAST(T1.`FRPM Count (K-12)` AS REAL) / T1.`Enrollment (K-12)` FROM frpm AS T1 JOIN schools AS T2 ON T1.CDSCode = T2.CDSCode WHERE T2.SOC = '66' ORDER BY T1.`FRPM Count (K-12)` DESC LIMIT 5	california_schools
SELECT s.Website, s.School AS "School Name" FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Free Meal Count (Ages 5-17)" BETWEEN 1900 AND 2000	california_schools
SELECT CAST(T2.`Free Meal Count (Ages 5-17)` AS REAL) / T2.`Enrollment (Ages 5-17)` FROM schools AS T1 INNER JOIN frpm AS T2 ON T1.CDSCode = T2.CDSCode WHERE T1.AdmFName1 = 'Kacey' AND T1.AdmLName1 = 'Gibson'	california_schools
SELECT s.AdmEmail1 FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE f."Charter School (Y/N)" = 1 ORDER BY f."Enrollment (K-12)" ASC LIMIT 1	california_schools
SELECT s.AdmFName1, s.AdmLName1, s.AdmFName2, s.AdmLName2, s.AdmFName3, s.AdmLName3 FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY sat.NumGE1500 DESC LIMIT 1	california_schools
SELECT s.Street, s.City, s.State, s.Zip FROM schools s JOIN satscores sat ON s.CDSCode = sat.cds WHERE sat.NumTstTakr > 0 ORDER BY CAST(sat.NumGE1500 AS REAL) / sat.NumTstTakr ASC LIMIT 1	california_schools
SELECT schools.Website FROM schools JOIN satscores ON CAST(schools.CDSCode AS INTEGER) = CAST(satscores.cds AS INTEGER) WHERE schools.County = 'Los Angeles' AND satscores.NumTstTakr BETWEEN 2000 AND 3000	california_schools
SELECT AVG(T1.NumTstTakr) FROM satscores AS T1 JOIN schools AS T2 ON T1.cds = T2.CDSCode WHERE T2.County = 'Fresno' AND date(T2.OpenDate) BETWEEN '1980-01-01' AND '1980-12-31'	california_schools
SELECT s.Phone FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE sat.dname = 'Fresno Unified' ORDER BY sat.AvgScrRead ASC LIMIT 1	california_schools
WITH ranked_schools AS ( SELECT s.School, RANK() OVER (PARTITION BY s.County ORDER BY sat.AvgScrRead DESC) as rnk FROM schools s JOIN satscores sat ON s.CDSCode = sat.cds WHERE s.Virtual = 'F' ) SELECT School FROM ranked_schools WHERE rnk <= 5	california_schools
SELECT s.EdOpsName FROM satscores sat JOIN schools s ON CAST(sat.cds AS INTEGER) = CAST(s.CDSCode AS INTEGER) ORDER BY sat.AvgScrMath DESC LIMIT 1	california_schools
SELECT s.AvgScrMath, sch.County FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE s.AvgScrMath IS NOT NULL AND s.AvgScrRead IS NOT NULL AND s.AvgScrWrite IS NOT NULL ORDER BY (s.AvgScrMath + s.AvgScrRead + s.AvgScrWrite) LIMIT 1	california_schools
SELECT s.AvgScrWrite, sch.City FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE s.NumGE1500 >= 1500 ORDER BY s.NumTstTakr DESC LIMIT 1	california_schools
SELECT s.School, sat.AvgScrWrite FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE s.AdmFName1 = 'Ricci' AND s.AdmLName1 = 'Ulrich'	california_schools
SELECT f."School Name" AS School FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE CAST(s.DOC AS INTEGER) = 31 ORDER BY f."Enrollment (K-12)" DESC LIMIT 1	california_schools
SELECT CAST(COUNT(School) AS REAL) / 12 FROM schools WHERE County = 'Alameda' AND DOC = '52' AND strftime('%Y', OpenDate) = '1980'	california_schools
SELECT CAST(SUM(CASE WHEN DOC = 54 THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN DOC = 52 THEN 1 ELSE 0 END) FROM schools WHERE StatusType = 'Merged' AND County = 'Orange' AND DOC IN ('54', '52')	california_schools
WITH closed_schools_by_county AS ( SELECT County, COUNT(*) as closed_count FROM schools WHERE StatusType = 'Closed' AND School IS NOT NULL AND ClosedDate IS NOT NULL GROUP BY County ), max_closed_county AS ( SELECT County FROM closed_schools_by_county ORDER BY closed_count DESC LIMIT 1 ) SELECT s.County, s.School, s.ClosedDate FROM schools s JOIN max_closed_county m ON s.County = m.County WHERE s.StatusType = 'Closed' AND s.School IS NOT NULL AND s.ClosedDate IS NOT NULL ORDER BY s.School	california_schools
SELECT s.MailStreet, s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrMath DESC LIMIT 1 OFFSET 6	california_schools
SELECT s.MailStreet, s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrRead ASC LIMIT 1	california_schools
SELECT COUNT(T1.cds) FROM satscores AS T1 JOIN schools AS T2 ON CAST(T1.cds AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.MailCity = 'Lakeport' AND (T1.AvgScrRead + T1.AvgScrMath + T1.AvgScrWrite) >= 1500	california_schools
SELECT s.NumTstTakr FROM satscores s JOIN schools sch ON CAST(s.cds AS INTEGER) = CAST(sch.CDSCode AS INTEGER) WHERE sch.MailCity = 'Fresno'	california_schools
SELECT "School", "MailZip" FROM schools WHERE ("AdmFName1" = 'Avetik' AND "AdmLName1" = 'Atoian') OR ("AdmFName2" = 'Avetik' AND "AdmLName2" = 'Atoian') OR ("AdmFName3" = 'Avetik' AND "AdmLName3" = 'Atoian')	california_schools
SELECT CAST(SUM(CASE WHEN County = 'Colusa' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN County = 'Humboldt' THEN 1 ELSE 0 END) FROM schools WHERE MailState = 'CA'	california_schools
SELECT COUNT(CDSCode) FROM schools WHERE MailCity = 'San Joaquin' AND MailState = 'CA' AND StatusType = 'Active'	california_schools
SELECT s.Phone, s.Ext FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) ORDER BY sat.AvgScrWrite DESC LIMIT 1 OFFSET 332	california_schools
SELECT "Phone", "Ext", "School" FROM schools WHERE "Zip" = '95203-3704'	california_schools
SELECT Website FROM schools WHERE (AdmFName1 = 'Mike' AND AdmLName1 = 'Larson') OR (AdmFName2 = 'Mike' AND AdmLName2 = 'Larson') OR (AdmFName3 = 'Mike' AND AdmLName3 = 'Larson') OR (AdmFName1 = 'Dante' AND AdmLName1 = 'Alvarez') OR (AdmFName2 = 'Dante' AND AdmLName2 = 'Alvarez') OR (AdmFName3 = 'Dante' AND AdmLName3 = 'Alvarez')	california_schools
SELECT Website FROM schools WHERE County = 'San Joaquin' AND Virtual = 'P' AND Charter = 1	california_schools
SELECT COUNT(School) FROM schools WHERE City = 'Hickman' AND Charter = 1 AND DOC = '52'	california_schools
SELECT COUNT(T2.School) FROM frpm AS T1 JOIN schools AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.Charter = 0 AND T2.County = 'Los Angeles' AND (T1."Free Meal Count (K-12)" * 100.0 / T1."Enrollment (K-12)") < 0.18	california_schools
SELECT AdmFName1, AdmLName1, School, City FROM schools WHERE Charter = 1 AND CharterNum = '00D2'	california_schools
SELECT COUNT(*) FROM schools WHERE MailCity = 'Hickman' AND CharterNum = '00D4'	california_schools
SELECT CAST(SUM(CASE WHEN FundingType = 'Locally funded' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN FundingType != 'Locally funded' THEN 1 ELSE 0 END) FROM schools WHERE County = 'Santa Clara' AND FundingType IS NOT NULL	california_schools
SELECT COUNT(School) FROM schools WHERE County = 'Stanislaus' AND FundingType = 'Directly funded' AND OpenDate BETWEEN '2000-01-01' AND '2005-12-31'	california_schools
SELECT COUNT(School) FROM schools WHERE City = 'San Francisco' AND DOCType = 'Community College District' AND STRFTIME('%Y', ClosedDate) = '1989'	california_schools
SELECT "County" FROM schools WHERE "SOC" = '11' AND "ClosedDate" IS NOT NULL AND CAST(STRFTIME('%Y', "ClosedDate") AS INTEGER) BETWEEN 1980 AND 1989 GROUP BY "County" ORDER BY COUNT(*) DESC LIMIT 1	california_schools
SELECT NCESDist FROM schools WHERE SOC = '31'	california_schools
SELECT COUNT(School) FROM schools WHERE County = 'Alpine' AND StatusType IN ('Active', 'Closed') AND EdOpsName = 'Community Day School'	california_schools
SELECT DISTINCT f."District Code" FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.City = 'Fresno' AND s.Magnet = 0	california_schools
SELECT frpm."Enrollment (Ages 5-17)" FROM frpm JOIN schools ON frpm.CDSCode = schools.CDSCode WHERE schools.City = 'Fremont' AND schools.EdOpsCode = 'SSS' AND frpm."Academic Year" = '2014-2015'	california_schools
SELECT f."FRPM Count (Ages 5-17)" FROM frpm f JOIN schools s ON CAST(f."CDSCode" AS INTEGER) = CAST(s."CDSCode" AS INTEGER) WHERE s."MailStreet" = 'PO Box 1040'	california_schools
SELECT MIN(T1.`Low Grade`) FROM frpm AS T1 JOIN schools AS T2 ON CAST(T1.CDSCode AS INTEGER) = CAST(T2.CDSCode AS INTEGER) WHERE T2.EdOpsCode = 'SPECON' AND T2.NCESDist = '0613360'	california_schools
SELECT s.EILName, s.School FROM frpm f JOIN schools s ON CAST(f.CDSCode AS INTEGER) = CAST(s.CDSCode AS INTEGER) WHERE f."NSLP Provision Status" = 'Breakfast Provision 2' AND f."County Code" = '37'	california_schools
SELECT s.City FROM schools s JOIN frpm f ON CAST(s.CDSCode AS INTEGER) = CAST(f.CDSCode AS INTEGER) WHERE s.County = 'Merced' AND s.EILCode = 'HS' AND f."NSLP Provision Status" = 'Lunch Provision 2' AND f."Low Grade" = '9' AND CAST(f."High Grade" AS INTEGER) = 12	california_schools
SELECT `School Name` AS School, `FRPM Count (Ages 5-17)` * 100.0 / `Enrollment (Ages 5-17)` FROM frpm WHERE `County Name` = 'Los Angeles' AND `Low Grade` IN ('K', 'KG') AND `High Grade` = '9'	california_schools
SELECT GSserved FROM schools WHERE City = 'Adelanto' GROUP BY GSserved ORDER BY COUNT(*) DESC LIMIT 1	california_schools
SELECT County, COUNT(Virtual) FROM schools WHERE County IN ('San Diego', 'Santa Barbara') AND Virtual = 'F' GROUP BY County ORDER BY COUNT(Virtual) DESC LIMIT 1	california_schools
SELECT EILName AS "School Type", School AS "School Name", Latitude FROM schools ORDER BY Latitude DESC LIMIT 1	california_schools
SELECT s.City, f."Low Grade", f."School Name" FROM schools s JOIN frpm f ON s.CDSCode = f.CDSCode WHERE s.State = 'CA' ORDER BY s.Latitude ASC LIMIT 1	california_schools
SELECT GSoffered FROM schools ORDER BY ABS(Longitude) DESC LIMIT 1	california_schools
SELECT T1.City, COUNT(T2.CDSCode) FROM schools AS T1 JOIN frpm AS T2 ON T1.CDSCode = T2.CDSCode WHERE T1.Magnet = 1 AND T1.GSoffered = 'K-8' AND T2."NSLP Provision Status" = 'Multiple Provision Types' GROUP BY T1.City	california_schools
SELECT AdmFName1, District FROM schools WHERE AdmFName1 IS NOT NULL GROUP BY AdmFName1, District ORDER BY COUNT(*) DESC LIMIT 2	california_schools
SELECT "Free Meal Count (K-12)" * 100.0 / "Enrollment (K-12)" AS "Free Meal Count (K-12) * 100 / Enrollment (K-12)", "District Code" FROM frpm JOIN schools ON frpm.CDSCode = schools.CDSCode WHERE schools.AdmFName1 = 'Alusine' OR schools.AdmFName2 = 'Alusine' OR schools.AdmFName3 = 'Alusine'	california_schools
SELECT AdmLName1, District, County, School FROM schools WHERE CharterNum = '0040'	california_schools
SELECT AdmEmail1, AdmEmail2 FROM schools WHERE County = 'San Bernardino' AND District = 'San Bernardino City Unified' AND OpenDate BETWEEN '2009-01-01' AND '2010-12-31' AND (CAST("SOC" AS INTEGER) = 62 OR CAST("DOC" AS INTEGER) = 54)	california_schools
SELECT s.AdmEmail1, s.School FROM schools s JOIN satscores sat ON CAST(s.CDSCode AS INTEGER) = CAST(sat.cds AS INTEGER) WHERE s.School IS NOT NULL ORDER BY sat.NumGE1500 DESC LIMIT 1	california_schools
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T2.frequency = 'POPLATEK PO OBRATU' AND T1.A3 = 'east Bohemia'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A3 = 'Prague'	financial
SELECT IIF(AVG(A13) > AVG(A12), '1996', '1995') FROM district	financial
SELECT COUNT(DISTINCT T2.district_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'F' AND T2.A11 > 6000 AND T2.A11 < 10000	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'M' AND T2.A3 = 'north Bohemia' AND T2.A11 > 8000	financial
SELECT a.account_id, (SELECT MAX(A11) - MIN(A11) FROM district) AS gap FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN district dist ON c.district_id = dist.district_id WHERE c.gender = 'F' ORDER BY c.birth_date ASC, dist.A11 ASC LIMIT 1	financial
SELECT a.account_id FROM account a JOIN disp d ON a.account_id = d.account_id JOIN client c ON d.client_id = c.client_id JOIN district dist ON c.district_id = dist.district_id WHERE c.birth_date = ( SELECT MAX(birth_date) FROM client ) ORDER BY CAST(dist.A11 AS INTEGER) DESC LIMIT 1	financial
SELECT COUNT(account.account_id) FROM disp JOIN account ON disp.account_id = account.account_id WHERE disp.type = 'OWNER' AND account.frequency = 'POPLATEK TYDNE'	financial
SELECT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id WHERE d.type = 'DISPONENT' AND a.frequency = 'POPLATEK PO OBRATU'	financial
SELECT a.account_id FROM account a JOIN loan l ON a.account_id = l.account_id WHERE l.status = 'A' AND STRFTIME('%Y', l.date) = '1997' AND a.frequency = 'POPLATEK TYDNE' ORDER BY l.amount ASC LIMIT 1	financial
SELECT account.account_id FROM account JOIN loan ON account.account_id = loan.account_id WHERE loan.duration > 12 AND STRFTIME('%Y', account.date) = '1993' ORDER BY loan.amount DESC LIMIT 1	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'F' AND STRFTIME('%Y', T1.birth_date) < '1950' AND T2.A2 = 'Sokolov'	financial
SELECT DISTINCT account_id FROM trans WHERE STRFTIME('%Y', date) = '1995' AND date = (SELECT MIN(date) FROM trans WHERE STRFTIME('%Y', date) = '1995')	financial
SELECT DISTINCT account.account_id FROM account JOIN trans ON account.account_id = trans.account_id WHERE account.date < '1997-01-01' AND trans.balance > 3000	financial
SELECT d.client_id FROM card c JOIN disp d ON c.disp_id = d.disp_id WHERE c.issued = '1994-03-03'	financial
SELECT a.date FROM trans t JOIN account a ON t.account_id = a.account_id WHERE t.date = '1998-10-14' AND t.amount = 840	financial
SELECT a.district_id FROM loan l JOIN account a ON l.account_id = a.account_id WHERE l.date = '1994-08-25'	financial
SELECT MAX(t.amount) AS amount FROM card c JOIN disp d ON c.disp_id = d.disp_id JOIN account a ON d.account_id = a.account_id JOIN trans t ON a.account_id = t.account_id WHERE c.issued = '1996-10-21'	financial
SELECT c.gender FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id WHERE a.district_id = ( SELECT district_id FROM district ORDER BY A11 DESC LIMIT 1 ) ORDER BY c.birth_date ASC LIMIT 1	financial
SELECT t.amount FROM trans t JOIN account a ON t.account_id = a.account_id WHERE t.account_id = ( SELECT account_id FROM loan ORDER BY amount DESC LIMIT 1 ) AND t.date >= a.date ORDER BY t.date LIMIT 1	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A2 = 'Jesenik' AND T1.gender = 'F'	financial
SELECT d.disp_id FROM disp d JOIN trans t ON d.account_id = t.account_id WHERE t.amount = 5100 AND date(t.date) = '1998-09-02'	financial
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A2 = 'Litomerice' AND STRFTIME('%Y', T2.date) = '1996'	financial
SELECT d.A2 FROM client c JOIN disp di ON c.client_id = di.client_id JOIN account a ON di.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE c.gender = 'F' AND c.birth_date = '1976-01-29'	financial
SELECT c.birth_date FROM loan l JOIN account a ON l.account_id = a.account_id JOIN disp d ON a.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE l.amount = 98832 AND l.date = '1996-01-03'	financial
SELECT a.account_id FROM account a JOIN district d ON a.district_id = d.district_id WHERE d.A3 = 'Prague' ORDER BY a.date LIMIT 1	financial
SELECT CAST(SUM(T1.gender = 'M') AS REAL) * 100 / COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A3 = 'south Bohemia' AND T2.district_id = ( SELECT district_id FROM district WHERE A3 = 'south Bohemia' ORDER BY CAST(A4 AS INTEGER) DESC LIMIT 1 )	financial
SELECT CAST((SUM(IIF(T2.date = '1998-12-27', T2.balance, 0)) - SUM(IIF(T2.date = '1993-03-22', T2.balance, 0))) AS REAL) * 100 / SUM(IIF(T2.date = '1993-03-22', T2.balance, 0)) FROM trans AS T2 WHERE T2.account_id = ( SELECT T1.account_id FROM loan AS T1 WHERE T1.date = '1993-07-05' ORDER BY T1.loan_id LIMIT 1 ) AND T2.date IN ('1993-03-22', '1998-12-27')	financial
SELECT (CAST(SUM(CASE WHEN status = 'A' THEN amount ELSE 0 END) AS REAL) * 100) / SUM(amount) FROM loan	financial
SELECT CAST(SUM(status = 'C') AS REAL) * 100 / COUNT(account_id) FROM loan WHERE amount < 100000	financial
SELECT a.account_id, d.A2, d.A3 FROM account a JOIN district d ON a.district_id = d.district_id WHERE STRFTIME('%Y', a.date) = '1993' AND a.frequency = 'POPLATEK PO OBRATU'	financial
SELECT a.account_id, a.frequency FROM account a JOIN district d ON a.district_id = d.district_id WHERE d.A3 = 'east Bohemia' AND STRFTIME('%Y', a.date) BETWEEN '1995' AND '2000'	financial
SELECT account.account_id, account.date FROM account JOIN district ON account.district_id = district.district_id WHERE district.A2 = 'Prachatice'	financial
SELECT d.A2, d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.loan_id = 4990	financial
SELECT l.account_id, d.A2, d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.amount > 300000	financial
SELECT l.loan_id, d.A2, d.A11 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.duration = 60	financial
SELECT CAST((T3.A13 - T3.A12) AS REAL) * 100 / T3.A12 FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id JOIN district AS T3 ON T2.district_id = T3.district_id WHERE T1.status = 'D'	financial
SELECT CAST(SUM(T1.A2 = 'Decin') AS REAL) * 100 / COUNT(account_id) FROM account AS T2 JOIN district AS T1 ON T1.district_id = T2.district_id WHERE STRFTIME('%Y', T2.date) = '1993'	financial
SELECT account_id FROM account WHERE frequency = 'POPLATEK MESICNE'	financial
SELECT d.A2, COUNT(c.client_id) FROM client c JOIN disp di ON c.client_id = di.client_id JOIN account a ON di.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE c.gender = 'F' GROUP BY d.A2 ORDER BY COUNT(c.client_id) DESC LIMIT 9	financial
SELECT d.A2 FROM trans t JOIN account a ON t.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE t.type = 'VYDAJ' AND t.date LIKE '1996-01%' ORDER BY t.amount DESC LIMIT 10	financial
SELECT COUNT(T3.account_id) FROM account AS T3 JOIN district AS T4 ON T3.district_id = T4.district_id JOIN disp AS T5 ON T3.account_id = T5.account_id AND T5.type = 'OWNER' LEFT JOIN card AS T6 ON T5.disp_id = T6.disp_id WHERE T4.A3 = 'south Bohemia' AND T6.card_id IS NULL	financial
SELECT d.A3 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.status IN ('C', 'D') GROUP BY d.A3 ORDER BY SUM(l.amount) DESC LIMIT 1	financial
SELECT AVG(T1.amount) FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id JOIN disp AS T3 ON T2.account_id = T3.account_id JOIN client AS T4 ON T3.client_id = T4.client_id WHERE T4.gender = 'M'	financial
SELECT district_id, A2 FROM district WHERE A13 = (SELECT MAX(A13) FROM district)	financial
SELECT COUNT(T2.account_id) FROM district AS T1 JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A16 = (SELECT MAX(CAST(A16 AS INTEGER)) FROM district)	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN trans AS T2 ON T1.account_id = T2.account_id WHERE T2.operation = 'VYBER KARTOU' AND T1.frequency = 'POPLATEK MESICNE' AND T2.balance < 0	financial
SELECT COUNT(T1.account_id) FROM loan AS T1 INNER JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.date BETWEEN '1995-01-01' AND '1997-12-31' AND T1.amount >= 250000 AND T2.frequency = 'POPLATEK MESICNE' AND T1.status = 'A'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 JOIN loan AS T2 ON T1.account_id = T2.account_id WHERE T1.district_id = 1 AND T2.status IN ('C', 'D')	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'M' AND T2.district_id = ( SELECT district_id FROM district ORDER BY CAST(A15 AS INTEGER) DESC LIMIT 1 OFFSET 1 )	financial
SELECT COUNT(T1.card_id) FROM card AS T1 INNER JOIN disp AS T2 ON T1.disp_id = T2.disp_id WHERE T1.type = 'gold' AND T2.type = 'OWNER'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T2.A2 = 'Pisek'	financial
SELECT DISTINCT a.district_id FROM trans t JOIN account a ON t.account_id = a.account_id WHERE STRFTIME('%Y', t.date) = '1997' AND t.amount > 10000	financial
SELECT DISTINCT o.account_id FROM "order" o JOIN account a ON o.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE o.k_symbol = 'SIPO' AND d.A2 = 'Pisek'	financial
SELECT a.account_id FROM account a JOIN disp d ON a.account_id = d.account_id JOIN card c ON d.disp_id = c.disp_id WHERE c.type = 'gold'	financial
SELECT AVG(T4.amount) FROM trans AS T4 WHERE T4.operation = 'VYBER KARTOU' AND STRFTIME('%Y', T4.date) = '2021'	financial
SELECT DISTINCT account_id FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) = '1998' AND amount < ( SELECT AVG(amount) FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) = '1998' )	financial
SELECT DISTINCT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN card ca ON d.disp_id = ca.disp_id JOIN loan l ON d.account_id = l.account_id WHERE c.gender = 'F' AND d.type = 'OWNER'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN account AS T3 ON T2.account_id = T3.account_id JOIN district AS T4 ON T3.district_id = T4.district_id WHERE T1.gender = 'F' AND T4.A3 = 'south Bohemia'	financial
SELECT a.account_id FROM account a JOIN district d ON a.district_id = d.district_id JOIN disp dp ON a.account_id = dp.account_id WHERE d.A2 = 'Tabor' AND dp.type = 'OWNER'	financial
SELECT DISTINCT d.type FROM disp d JOIN account a ON d.account_id = a.account_id JOIN district dist ON a.district_id = dist.district_id WHERE d.type != 'OWNER' AND dist.A11 BETWEEN 8000 AND 9000	financial
SELECT COUNT(DISTINCT T2.account_id) FROM account AS T2 JOIN district AS T1 ON T2.district_id = T1.district_id JOIN trans AS T3 ON T2.account_id = T3.account_id WHERE T1.A3 = 'north Bohemia' AND T3.bank = 'AB'	financial
SELECT DISTINCT d.A2 FROM trans t JOIN account a ON t.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE t.type = 'VYDAJ'	financial
SELECT AVG(T1.A15) FROM district AS T1 JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A15 > 4000 AND T2.date >= '1997-01-01'	financial
SELECT COUNT(T1.card_id) FROM card AS T1 JOIN disp AS T2 ON T1.disp_id = T2.disp_id WHERE T1.type = 'classic' AND T2.type = 'OWNER'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 INNER JOIN district AS T2 ON T1.district_id = T2.district_id WHERE T1.gender = 'M' AND T2.A2 = 'Hl.m. Praha'	financial
SELECT CAST(SUM(type = 'gold' AND STRFTIME('%Y', issued) < '1998') AS REAL) * 100 / COUNT(card_id) FROM card	financial
SELECT c.client_id FROM loan l JOIN account a ON l.account_id = a.account_id JOIN disp d ON a.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE d.type = 'OWNER' ORDER BY l.amount DESC LIMIT 1	financial
SELECT d.A15 FROM account a JOIN district d ON a.district_id = d.district_id WHERE a.account_id = 532	financial
SELECT a.district_id FROM "order" o JOIN account a ON o.account_id = a.account_id WHERE o.order_id = 33333	financial
SELECT t.trans_id FROM trans t JOIN disp d ON t.account_id = d.account_id WHERE d.client_id = 3356 AND t.operation = 'VYBER'	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN loan AS T2 ON T1.account_id = T2.account_id WHERE T1.frequency = 'POPLATEK TYDNE' AND T2.amount < 200000	financial
SELECT card.type FROM client JOIN disp ON client.client_id = disp.client_id JOIN card ON disp.disp_id = card.disp_id WHERE client.client_id = 13539	financial
SELECT d.A3 FROM client c JOIN district d ON c.district_id = d.district_id WHERE c.client_id = 3541	financial
SELECT d.A2 FROM loan l JOIN account a ON l.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE l.status = 'A' GROUP BY d.district_id, d.A2 ORDER BY COUNT(*) DESC LIMIT 1	financial
SELECT d.client_id FROM "order" o JOIN disp d ON o.account_id = d.account_id WHERE o.order_id = 32423	financial
SELECT t.trans_id FROM trans t JOIN account a ON t.account_id = a.account_id WHERE a.district_id = 5	financial
SELECT COUNT(T2.account_id) FROM district AS T1 INNER JOIN account AS T2 ON T1.district_id = T2.district_id WHERE T1.A2 = 'Jesenik'	financial
SELECT DISTINCT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN card ca ON d.disp_id = ca.disp_id WHERE ca.type = 'junior' AND ca.issued >= '1997-01-01'	financial
SELECT CAST(SUM(T2.gender = 'F') AS REAL) * 100 / COUNT(T2.client_id) FROM account AS T1 JOIN client AS T2 ON T1.district_id = T2.district_id JOIN district AS T3 ON T1.district_id = T3.district_id WHERE T3.A11 > 10000	financial
SELECT CAST((SUM(CASE WHEN STRFTIME('%Y', T1.date) = '1997' THEN T1.amount ELSE 0 END) - SUM(CASE WHEN STRFTIME('%Y', T1.date) = '1996' THEN T1.amount ELSE 0 END)) AS REAL) * 100 / SUM(CASE WHEN STRFTIME('%Y', T1.date) = '1996' THEN T1.amount ELSE 0 END) FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id JOIN disp AS T3 ON T2.account_id = T3.account_id JOIN client AS T4 ON T3.client_id = T4.client_id WHERE T4.gender = 'M'	financial
SELECT COUNT(account_id) FROM trans WHERE operation = 'VYBER KARTOU' AND STRFTIME('%Y', date) > '1995'	financial
SELECT SUM(IIF(A3 = 'east Bohemia', A16, 0)) - SUM(IIF(A3 = 'north Bohemia', A16, 0)) FROM district	financial
SELECT SUM(type = 'OWNER') AS "SUM(type = 'OWNER')", SUM(type = 'DISPONENT') AS "SUM(type = 'DISPONENT')" FROM disp WHERE account_id BETWEEN 1 AND 10	financial
SELECT DISTINCT a.frequency, TRIM(t.k_symbol) AS k_symbol FROM account a CROSS JOIN trans t WHERE a.account_id = 3 AND t.amount = 3539 AND t.type = 'VYDAJ'	financial
SELECT STRFTIME('%Y', T1.birth_date) FROM client AS T1 WHERE T1.client_id = 130	financial
SELECT COUNT(T1.account_id) FROM account AS T1 INNER JOIN disp AS T2 ON T1.account_id = T2.account_id WHERE T2.type = 'OWNER' AND T1.frequency = 'POPLATEK PO OBRATU'	financial
SELECT l.amount, l.status FROM client c JOIN disp d ON c.client_id = d.client_id JOIN loan l ON d.account_id = l.account_id WHERE c.client_id = 992	financial
SELECT t.balance, c.gender FROM trans t JOIN disp d ON t.account_id = d.account_id JOIN client c ON d.client_id = c.client_id WHERE t.trans_id = 851 AND c.client_id = 4	financial
SELECT card.type FROM client JOIN disp ON client.client_id = disp.client_id JOIN card ON disp.disp_id = card.disp_id WHERE client.client_id = 9	financial
SELECT SUM(T3.amount) FROM client AS T1 INNER JOIN disp AS T2 ON T1.client_id = T2.client_id INNER JOIN account AS T4 ON T2.account_id = T4.account_id INNER JOIN trans AS T3 ON T4.account_id = T3.account_id WHERE T1.client_id = 617 AND STRFTIME('%Y', T3.date) = '1998' AND T3.type = 'VYDAJ'	financial
SELECT c.client_id, a.account_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN district dist ON a.district_id = dist.district_id WHERE c.birth_date BETWEEN '1983-01-01' AND '1987-12-31' AND dist.A3 = 'east Bohemia'	financial
SELECT c.client_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN account a ON d.account_id = a.account_id JOIN loan l ON a.account_id = l.account_id WHERE c.gender = 'F' ORDER BY l.amount DESC LIMIT 3	financial
SELECT COUNT(T1.account_id) FROM client AS T2 JOIN disp AS T3 ON T2.client_id = T3.client_id JOIN "order" AS T1 ON T3.account_id = T1.account_id WHERE T2.gender = 'M' AND STRFTIME('%Y', T2.birth_date) BETWEEN '1974' AND '1976' AND T1.k_symbol = 'SIPO' AND T1.amount > 4000	financial
SELECT COUNT(account_id) FROM account JOIN district ON account.district_id = district.district_id WHERE district.A2 = 'Beroun' AND date(account.date) > '1996-12-31'	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN card AS T3 ON T2.disp_id = T3.disp_id WHERE T1.gender = 'F' AND T3.type = 'junior'	financial
SELECT CAST(SUM(T2.gender = 'F') AS REAL) / COUNT(T2.client_id) * 100 FROM district AS T1 JOIN account AS T3 ON T1.district_id = T3.district_id JOIN disp AS T4 ON T3.account_id = T4.account_id JOIN client AS T2 ON T4.client_id = T2.client_id WHERE T1.A3 = 'Prague'	financial
SELECT CAST(SUM(T1.gender = 'M') AS REAL) * 100 / COUNT(T1.client_id) FROM client AS T1 JOIN disp AS T2 ON T1.client_id = T2.client_id JOIN account AS T3 ON T2.account_id = T3.account_id WHERE T3.frequency = 'POPLATEK TYDNE'	financial
SELECT COUNT(T2.account_id) FROM account AS T1 JOIN disp AS T2 ON T1.account_id = T2.account_id WHERE T1.frequency = 'POPLATEK TYDNE' AND T2.type = 'OWNER'	financial
SELECT a.account_id FROM account a JOIN loan l ON a.account_id = l.account_id WHERE l.duration > 24 AND l.status = 'A' AND date(a.date) < '1997-01-01' ORDER BY l.amount ASC LIMIT 1	financial
SELECT d.account_id FROM client c JOIN disp d ON c.client_id = d.client_id JOIN district dist ON c.district_id = dist.district_id WHERE c.gender = 'F' AND c.birth_date = (SELECT MIN(c2.birth_date) FROM client c2 WHERE c2.gender = 'F') AND dist.A11 = (SELECT MIN(dist2.A11) FROM client c3 JOIN district dist2 ON c3.district_id = dist2.district_id WHERE c3.gender = 'F' AND c3.birth_date = (SELECT MIN(c4.birth_date) FROM client c4 WHERE c4.gender = 'F'))	financial
SELECT COUNT(T1.client_id) FROM client AS T1 JOIN district AS T2 ON T1.district_id = T2.district_id WHERE STRFTIME('%Y', T1.birth_date) = '1920' AND T2.A3 = 'east Bohemia'	financial
SELECT COUNT(T2.account_id) FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.duration = 24 AND T2.frequency = 'POPLATEK TYDNE'	financial
SELECT AVG(T1.amount) FROM loan AS T1 JOIN account AS T2 ON T1.account_id = T2.account_id WHERE T1.status IN ('C', 'D') AND T2.frequency = 'POPLATEK PO OBRATU'	financial
SELECT c.client_id, a.district_id, d.A2 FROM client c JOIN disp di ON c.client_id = di.client_id JOIN account a ON di.account_id = a.account_id JOIN district d ON a.district_id = d.district_id WHERE di.type = 'OWNER'	financial
SELECT c.client_id, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', c.birth_date) FROM client c JOIN disp d ON c.client_id = d.client_id JOIN card ca ON d.disp_id = ca.disp_id WHERE ca.type = 'gold' AND d.type = 'OWNER'	financial
SELECT bond_type FROM bond GROUP BY bond_type ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '-' AND a.element = 'cl'	toxicology
SELECT AVG(oxygen_count) AS "AVG(oxygen_count)" FROM ( SELECT m.molecule_id, COUNT(CASE WHEN a.element = 'o' THEN 1 END) AS oxygen_count FROM molecule m INNER JOIN bond b ON m.molecule_id = b.molecule_id INNER JOIN atom a ON m.molecule_id = a.molecule_id WHERE b.bond_type = '-' GROUP BY m.molecule_id )	toxicology
SELECT AVG(single_bond_count) FROM ( SELECT m.molecule_id, SUM(CASE WHEN b.bond_type = '-' THEN 1 ELSE 0 END) AS single_bond_count FROM molecule m LEFT JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '+' GROUP BY m.molecule_id )	toxicology
SELECT COUNT(DISTINCT T2.molecule_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.element = 'na' AND T2.label = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE b.bond_type = '#' AND m.label = '+'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T1.element = 'c' THEN T1.atom_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T1.atom_id) FROM atom AS T1 INNER JOIN bond AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.bond_type = '='	toxicology
SELECT COUNT(T.bond_id) FROM bond AS T WHERE T.bond_type = '#'	toxicology
SELECT COUNT(DISTINCT atom_id) FROM atom WHERE element != 'br'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE molecule_id BETWEEN 'TR000' AND 'TR099' AND label = '+'	toxicology
SELECT DISTINCT molecule_id FROM atom WHERE element = 'c'	toxicology
SELECT a.element FROM connected c JOIN atom a ON a.atom_id IN (c.atom_id, c.atom_id2) WHERE c.bond_id = 'TR004_8_9'	toxicology
SELECT DISTINCT a.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON c.atom_id = a.atom_id WHERE b.bond_type = '='	toxicology
SELECT m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.element = 'h' GROUP BY m.label ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'cl'	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '-'	toxicology
SELECT atom.atom_id FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '-'	toxicology
SELECT element FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '-' GROUP BY element ORDER BY COUNT(*) ASC LIMIT 1	toxicology
SELECT DISTINCT b.bond_type FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE (c.atom_id = 'TR004_8' AND c.atom_id2 = 'TR004_20') OR (c.atom_id = 'TR004_20' AND c.atom_id2 = 'TR004_8')	toxicology
SELECT DISTINCT label FROM molecule EXCEPT SELECT DISTINCT m.label FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'sn'	toxicology
SELECT COUNT(DISTINCT CASE WHEN a.element = 'i' THEN a.atom_id END) as iodine_nums, COUNT(DISTINCT CASE WHEN a.element = 's' THEN a.atom_id END) as sulfur_nums FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '-'	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '#'	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN atom a ON c.atom_id = a.atom_id WHERE a.molecule_id = 'TR181'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T1.element <> 'f' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T2.molecule_id) FROM atom AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '+'	toxicology
SELECT CAST(COUNT(DISTINCT CASE WHEN T2.label = '+' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(DISTINCT T2.molecule_id) FROM bond AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '#'	toxicology
SELECT element FROM (SELECT element, COUNT(*) as cnt FROM atom WHERE molecule_id = 'TR000' GROUP BY element ORDER BY cnt DESC LIMIT 3) ORDER BY element ASC	toxicology
SELECT c.atom_id AS atom_id1, c.atom_id2 AS atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.molecule_id = 'TR001' AND c.bond_id = 'TR001_2_6'	toxicology
SELECT SUM(CASE WHEN label = '+' THEN 1 ELSE 0 END) - SUM(CASE WHEN label = '-' THEN 1 ELSE 0 END) AS diff_car_notcar FROM molecule	toxicology
SELECT atom_id FROM connected WHERE bond_id = 'TR000_2_5' UNION SELECT atom_id2 FROM connected WHERE bond_id = 'TR000_2_5'	toxicology
SELECT bond_id FROM connected WHERE atom_id2 = 'TR000_2'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE b.bond_type = '=' ORDER BY m.molecule_id LIMIT 5	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T.bond_type = '=' THEN T.bond_id ELSE NULL END) AS REAL) * 100 / COUNT(T.bond_id), 5) FROM bond AS T WHERE T.molecule_id = 'TR008'	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T.label = '+' THEN T.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(T.molecule_id), 3) FROM molecule AS T	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN element = 'h' THEN atom_id ELSE NULL END) AS REAL) * 100 / COUNT(atom_id), 4) FROM atom WHERE molecule_id = 'TR206'	toxicology
SELECT DISTINCT bond_type FROM bond WHERE molecule_id = 'TR000'	toxicology
SELECT a.element, m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.molecule_id = 'TR060'	toxicology
SELECT bond_type FROM bond WHERE molecule_id = 'TR010' GROUP BY bond_type ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND b.bond_type = '-' ORDER BY m.molecule_id LIMIT 3	toxicology
SELECT bond_id FROM bond WHERE molecule_id = 'TR006' ORDER BY bond_id LIMIT 2	toxicology
SELECT COUNT(T2.bond_id) FROM connected AS T1 JOIN bond AS T2 ON T1.bond_id = T2.bond_id WHERE T2.molecule_id = 'TR009' AND (T1.atom_id = 'TR009_12' OR T1.atom_id2 = 'TR009_12')	toxicology
SELECT COUNT(DISTINCT T2.molecule_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '+' AND T1.element = 'br'	toxicology
SELECT b.bond_type, c.atom_id, c.atom_id2 FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.bond_id = 'TR001_6_9'	toxicology
SELECT a.molecule_id, IIF(m.label = '+', 'YES', 'NO') AS flag_carcinogenic FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR001_10'	toxicology
SELECT COUNT(DISTINCT molecule_id) FROM bond WHERE bond_type = '#'	toxicology
SELECT COUNT(T.bond_id) FROM connected AS T WHERE T.atom_id LIKE 'TR%_19' OR T.atom_id2 LIKE 'TR%_19'	toxicology
SELECT DISTINCT element FROM atom WHERE molecule_id = 'TR004'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE SUBSTR(a.atom_id, 7, 2) BETWEEN '21' AND '25' AND m.label = '+'	toxicology
SELECT DISTINCT b.bond_id FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE (a1.element = 'p' AND a2.element = 'n') OR (a1.element = 'n' AND a2.element = 'p')	toxicology
SELECT m.label FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE b.bond_type = '=' GROUP BY m.molecule_id, m.label ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT CAST(COUNT(T2.bond_id) AS REAL) / COUNT(T1.atom_id) FROM atom T1 LEFT JOIN connected T2 ON T1.atom_id = T2.atom_id WHERE T1.element = 'i'	toxicology
SELECT DISTINCT b.bond_type, b.bond_id FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE SUBSTR(a.atom_id, 7, 2) + 0 = 45	toxicology
SELECT DISTINCT element FROM atom WHERE atom_id NOT IN (SELECT atom_id FROM connected)	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.molecule_id = 'TR041' AND b.bond_type = '#'	toxicology
SELECT element FROM atom WHERE atom_id IN ( SELECT atom_id FROM connected WHERE bond_id = 'TR144_8_19' UNION SELECT atom_id2 FROM connected WHERE bond_id = 'TR144_8_19' )	toxicology
SELECT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '+' AND b.bond_type = '=' GROUP BY m.molecule_id ORDER BY COUNT(*) DESC LIMIT 1	toxicology
SELECT element FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE molecule.label = '+' GROUP BY element ORDER BY COUNT(*) ASC LIMIT 1	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN atom a ON c.atom_id = a.atom_id WHERE a.element = 'pb' UNION SELECT c.atom_id2, c.atom_id FROM connected c JOIN atom a ON c.atom_id2 = a.atom_id WHERE a.element = 'pb'	toxicology
SELECT a1.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id WHERE b.bond_type = '#' UNION SELECT a2.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE b.bond_type = '#'	toxicology
SELECT CAST((SELECT COUNT(T1.atom_id) FROM connected AS T1 INNER JOIN bond AS T2 ON T1.bond_id = T2.bond_id GROUP BY T2.bond_type ORDER BY COUNT(T2.bond_id) DESC LIMIT 1 ) AS REAL) * 100 / ( SELECT COUNT(atom_id) FROM connected )	toxicology
SELECT ROUND(CAST(COUNT(CASE WHEN T2.label = '+' THEN T1.bond_id ELSE NULL END) AS REAL) * 100 / COUNT(T1.bond_id), 5) FROM bond AS T1 JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '-'	toxicology
SELECT COUNT(T.atom_id) FROM atom AS T WHERE T.element IN ('c', 'h')	toxicology
SELECT c.atom_id2 FROM connected c JOIN atom a ON c.atom_id = a.atom_id WHERE a.element = 's'	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'sn'	toxicology
SELECT COUNT(DISTINCT atom.element) FROM atom JOIN bond ON atom.molecule_id = bond.molecule_id WHERE bond.bond_type = '-'	toxicology
SELECT COUNT(T1.atom_id) FROM atom AS T1 INNER JOIN molecule m ON T1.molecule_id = m.molecule_id WHERE m.molecule_id IN ( SELECT DISTINCT b.molecule_id FROM bond b WHERE b.bond_type = '#' ) AND m.molecule_id IN ( SELECT DISTINCT a.molecule_id FROM atom a WHERE a.element IN ('p', 'br') )	toxicology
SELECT bond.bond_id FROM bond JOIN molecule ON bond.molecule_id = molecule.molecule_id WHERE molecule.label = '+'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN bond b ON m.molecule_id = b.molecule_id WHERE m.label = '-' AND b.bond_type = '-'	toxicology
SELECT CAST(COUNT(CASE WHEN a.element = 'cl' THEN a.atom_id ELSE NULL END) AS REAL) * 100 / COUNT(a.atom_id) FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE b.bond_type = '-'	toxicology
SELECT molecule_id, label FROM molecule WHERE molecule_id IN ('TR000', 'TR001', 'TR002')	toxicology
SELECT molecule_id FROM molecule WHERE label = '-'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '+' AND molecule_id BETWEEN 'TR000' AND 'TR030'	toxicology
SELECT molecule_id, bond_type FROM bond WHERE molecule_id BETWEEN 'TR000' AND 'TR050'	toxicology
SELECT DISTINCT a.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON (a.atom_id = c.atom_id OR a.atom_id = c.atom_id2) WHERE b.bond_id = 'TR001_10_11'	toxicology
SELECT COUNT(T3.bond_id) FROM atom AS T1 JOIN connected AS T3 ON T1.atom_id = T3.atom_id WHERE T1.element = 'i'	toxicology
SELECT MAX(m.label) AS label FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'ca'	toxicology
SELECT b.bond_id, c.atom_id2, a.element as flag_have_CaCl FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON c.atom_id2 = a.atom_id WHERE b.bond_id = 'TR001_1_8' AND a.element IN ('c', 'cl')	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id JOIN bond b ON m.molecule_id = b.molecule_id WHERE a.element = 'c' AND b.bond_type = '#' AND m.label = '-' LIMIT 2	toxicology
SELECT CAST(SUM(CASE WHEN a.element = 'cl' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) AS percentage FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE m.label = '+'	toxicology
SELECT DISTINCT element FROM atom WHERE molecule_id = 'TR001'	toxicology
SELECT DISTINCT molecule_id FROM bond WHERE bond_type = '='	toxicology
SELECT c.atom_id, c.atom_id2 FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE b.bond_type = '#'	toxicology
SELECT element FROM atom JOIN connected ON atom.atom_id = connected.atom_id WHERE connected.bond_id = 'TR000_1_2' UNION SELECT element FROM atom JOIN connected ON atom.atom_id = connected.atom_id2 WHERE connected.bond_id = 'TR000_1_2'	toxicology
SELECT COUNT(DISTINCT T2.molecule_id) FROM bond AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '-' AND T1.bond_type = '-'	toxicology
SELECT m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_id = 'TR001_10_11'	toxicology
SELECT b.bond_id, m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_type = '#'	toxicology
SELECT a.element FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE m.label = '+' AND substr(a.atom_id, 7, 1) = '4'	toxicology
SELECT CAST(SUM(CASE WHEN a.element = 'h' THEN 1 ELSE 0 END) AS REAL) / COUNT(*) AS ratio, m.label FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.molecule_id = 'TR006' GROUP BY m.label	toxicology
SELECT m.label AS flag_carcinogenic FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.element = 'ca'	toxicology
SELECT DISTINCT b.bond_type FROM atom a JOIN connected c ON a.atom_id = c.atom_id OR a.atom_id = c.atom_id2 JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'c'	toxicology
SELECT a1.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR001_10_11' UNION SELECT a2.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR001_10_11'	toxicology
SELECT CAST(COUNT(CASE WHEN bond_type = '#' THEN bond_id ELSE NULL END) AS REAL) * 100 / COUNT(bond_id) FROM bond	toxicology
SELECT CAST(COUNT(CASE WHEN bond_type = '=' THEN bond_id ELSE NULL END) AS REAL) * 100 / COUNT(bond_id) FROM bond WHERE molecule_id = 'TR047'	toxicology
SELECT m.label AS flag_carcinogenic FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR001_1'	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR151'	toxicology
SELECT DISTINCT element FROM atom WHERE molecule_id = 'TR151'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '+'	toxicology
SELECT atom_id FROM atom WHERE element = 'c' AND CAST(substr(molecule_id, 3, 3) AS INTEGER) >= 10 AND CAST(substr(molecule_id, 3, 3) AS INTEGER) <= 50	toxicology
SELECT COUNT(T1.atom_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.label = '+'	toxicology
SELECT bond.bond_id FROM bond JOIN molecule ON bond.molecule_id = molecule.molecule_id WHERE bond.bond_type = '=' AND molecule.label = '+'	toxicology
SELECT COUNT(*) AS atomnums_h FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE atom.element = 'h' AND molecule.label = '+'	toxicology
SELECT DISTINCT b.molecule_id, b.bond_id, CASE WHEN c.atom_id = 'TR000_1' THEN c.atom_id WHEN c.atom_id2 = 'TR000_1' THEN c.atom_id2 END AS atom_id FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.bond_id = 'TR000_1_2' AND (c.atom_id = 'TR000_1' OR c.atom_id2 = 'TR000_1')	toxicology
SELECT atom.atom_id FROM atom JOIN molecule ON atom.molecule_id = molecule.molecule_id WHERE atom.element = 'c' AND molecule.label = '-'	toxicology
SELECT CAST(COUNT(CASE WHEN T1.element = 'h' AND T2.label = '+' THEN T2.molecule_id ELSE NULL END) AS REAL) * 100 / COUNT(T2.molecule_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR124'	toxicology
SELECT atom_id FROM atom WHERE molecule_id = 'TR186'	toxicology
SELECT bond_type FROM bond WHERE bond_id = 'TR007_4_19'	toxicology
SELECT a1.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a1 ON c.atom_id = a1.atom_id WHERE b.bond_id = 'TR001_2_4' UNION SELECT a2.element FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE b.bond_id = 'TR001_2_4'	toxicology
SELECT COUNT(b.bond_id), m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.molecule_id = 'TR006' AND b.bond_type = '=' GROUP BY m.label	toxicology
SELECT DISTINCT m.molecule_id, a.element FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '+'	toxicology
SELECT b.bond_id, c.atom_id, c.atom_id2 FROM bond b JOIN connected c ON b.bond_id = c.bond_id WHERE b.bond_type = '-'	toxicology
SELECT DISTINCT b.molecule_id, a.element FROM bond b JOIN atom a ON b.molecule_id = a.molecule_id WHERE b.bond_type = '#' ORDER BY b.molecule_id, a.element	toxicology
SELECT a1.element FROM connected c JOIN atom a1 ON c.atom_id = a1.atom_id WHERE c.bond_id = 'TR000_2_3' UNION SELECT a2.element FROM connected c JOIN atom a2 ON c.atom_id2 = a2.atom_id WHERE c.bond_id = 'TR000_2_3'	toxicology
SELECT COUNT(T1.bond_id) FROM connected AS T1 JOIN atom AS T2 ON T1.atom_id = T2.atom_id JOIN atom AS T3 ON T1.atom_id2 = T3.atom_id WHERE T2.element = 'cl' OR T3.element = 'cl'	toxicology
SELECT T1.atom_id, COUNT(DISTINCT T2.bond_type), T1.molecule_id FROM atom AS T1 INNER JOIN bond AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.molecule_id = 'TR346' GROUP BY T1.atom_id, T1.molecule_id	toxicology
SELECT COUNT(DISTINCT T2.molecule_id), SUM(CASE WHEN T2.label = '+' THEN 1 ELSE 0 END) FROM bond AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.bond_type = '='	toxicology
SELECT COUNT(DISTINCT m.molecule_id) FROM molecule m WHERE m.molecule_id NOT IN ( SELECT a.molecule_id FROM atom a WHERE a.element = 's' ) AND m.molecule_id NOT IN ( SELECT b.molecule_id FROM bond b WHERE b.bond_type = '=' )	toxicology
SELECT m.label FROM bond b JOIN molecule m ON b.molecule_id = m.molecule_id WHERE b.bond_id = 'TR001_2_4'	toxicology
SELECT COUNT(atom.atom_id) FROM atom WHERE atom.molecule_id = 'TR001'	toxicology
SELECT COUNT(bond_id) FROM bond WHERE bond_type = '-'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'cl' AND m.label = '+'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 'c' AND m.label = '-'	toxicology
SELECT COUNT(CASE WHEN T2.label = '+' AND T1.element = 'cl' THEN T2.molecule_id ELSE NULL END) * 100 / COUNT(T2.molecule_id) FROM atom AS T1 INNER JOIN molecule AS T2 ON T1.molecule_id = T2.molecule_id	toxicology
SELECT molecule_id FROM bond WHERE bond_id = 'TR001_1_7'	toxicology
SELECT COUNT(DISTINCT a.element) FROM bond b JOIN connected c ON b.bond_id = c.bond_id JOIN atom a ON (a.atom_id = c.atom_id OR a.atom_id = c.atom_id2) WHERE b.bond_id = 'TR001_3_4'	toxicology
SELECT DISTINCT b.bond_type FROM connected c JOIN bond b ON c.bond_id = b.bond_id WHERE (c.atom_id = 'TR000_1' AND c.atom_id2 = 'TR000_2') OR (c.atom_id = 'TR000_2' AND c.atom_id2 = 'TR000_1')	toxicology
SELECT molecule_id FROM atom WHERE atom_id = 'TR000_2' INTERSECT SELECT molecule_id FROM atom WHERE atom_id = 'TR000_4'	toxicology
SELECT element FROM atom WHERE atom_id = 'TR000_1'	toxicology
SELECT label FROM molecule WHERE molecule_id = 'TR000'	toxicology
SELECT CAST(SUM(CASE WHEN bond_type = '-' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(bond_id) AS percentage FROM bond	toxicology
SELECT COUNT(DISTINCT T1.molecule_id) FROM molecule AS T1 INNER JOIN atom AS T2 ON T1.molecule_id = T2.molecule_id WHERE T1.label = '+' AND T2.element = 'n'	toxicology
SELECT DISTINCT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE a.element = 's' AND EXISTS ( SELECT 1 FROM bond b WHERE b.molecule_id = m.molecule_id AND b.bond_type = '=' )	toxicology
SELECT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '-' GROUP BY m.molecule_id HAVING COUNT(a.atom_id) > 5	toxicology
SELECT DISTINCT a.element FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE a.molecule_id = 'TR024' AND b.bond_type = '='	toxicology
SELECT m.molecule_id FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id WHERE m.label = '+' GROUP BY m.molecule_id ORDER BY COUNT(a.atom_id) DESC LIMIT 1	toxicology
SELECT CAST(SUM(CASE WHEN m.label = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(DISTINCT m.molecule_id) FROM molecule m JOIN atom a ON m.molecule_id = a.molecule_id JOIN bond b ON m.molecule_id = b.molecule_id WHERE a.element = 'h' AND b.bond_type = '#'	toxicology
SELECT COUNT(molecule_id) FROM molecule WHERE label = '+'	toxicology
SELECT COUNT(DISTINCT molecule_id) FROM bond WHERE bond_type = '-' AND molecule_id BETWEEN 'TR004' AND 'TR010'	toxicology
SELECT COUNT(atom.atom_id) FROM atom WHERE atom.molecule_id = 'TR008' AND atom.element = 'c'	toxicology
SELECT a.element FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.atom_id = 'TR004_7' AND m.label = '-'	toxicology
SELECT COUNT(DISTINCT atom.molecule_id) FROM atom JOIN connected ON atom.atom_id = connected.atom_id JOIN bond ON connected.bond_id = bond.bond_id WHERE atom.element = 'o' AND bond.bond_type = '='	toxicology
SELECT COUNT(DISTINCT T1.molecule_id) FROM molecule AS T1 INNER JOIN bond AS T2 ON T1.molecule_id = T2.molecule_id WHERE T2.bond_type = '#' AND T1.label = '-'	toxicology
SELECT a.element, b.bond_type FROM atom a JOIN bond b ON a.molecule_id = b.molecule_id WHERE a.molecule_id = 'TR002'	toxicology
SELECT a.atom_id FROM atom a JOIN connected c ON a.atom_id = c.atom_id JOIN bond b ON c.bond_id = b.bond_id WHERE a.element = 'c' AND b.bond_type = '=' AND a.molecule_id = 'TR012'	toxicology
SELECT a.atom_id FROM atom a JOIN molecule m ON a.molecule_id = m.molecule_id WHERE a.element = 'o' AND m.label = '+'	toxicology
SELECT id FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT id FROM cards WHERE borderColor = 'borderless' AND (cardKingdomFoilId IS NULL OR cardKingdomId IS NULL)	card_games
SELECT DISTINCT name FROM cards WHERE faceConvertedManaCost = (SELECT MAX(faceConvertedManaCost) FROM cards WHERE faceConvertedManaCost IS NOT NULL)	card_games
SELECT id FROM cards WHERE frameVersion = '2015' AND edhrecRank < 100	card_games
SELECT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.rarity = 'mythic' AND l.status = 'Banned' AND l.format = 'gladiator'	card_games
SELECT l.status FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.types = 'Artifact' AND c.side IS NULL AND l.format = 'vintage'	card_games
SELECT c.id, c.artist FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE (c.power = '*' OR c.power IS NULL) AND l.format = 'commander' AND l.status = 'Legal'	card_games
SELECT c.id, r.text, c.hasContentWarning FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.artist = 'Stephen Daniele'	card_games
SELECT r.text FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.name = 'Sublime Epiphany' AND c.number = '74s'	card_games
SELECT c.name, c.artist, c.isPromo FROM cards c JOIN ( SELECT uuid, COUNT(*) as ruling_count FROM rulings GROUP BY uuid ORDER BY ruling_count DESC LIMIT 1 ) r ON c.uuid = r.uuid	card_games
SELECT fd.language FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE LOWER(c.name) = 'annul' AND c.number = '29'	card_games
SELECT DISTINCT c.name FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE f.language = 'Japanese'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'Chinese Simplified' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 LEFT JOIN foreign_data AS T2 ON T1.uuid = T2.uuid	card_games
SELECT s.name, s.totalSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.language = 'Italian' ORDER BY s.name	card_games
SELECT COUNT(DISTINCT type) FROM cards WHERE artist = 'Aaron Boyd'	card_games
SELECT DISTINCT keywords FROM cards WHERE name = 'Angel of Mercy'	card_games
SELECT COUNT(*) FROM cards WHERE power = '*'	card_games
SELECT DISTINCT promoTypes FROM cards WHERE name = 'Duress' AND promoTypes IS NOT NULL	card_games
SELECT borderColor FROM cards WHERE name = 'Ancestor''s Chosen'	card_games
SELECT originalType FROM cards WHERE name = 'Ancestor''s Chosen'	card_games
SELECT DISTINCT st.language FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Angel of Mercy'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Restricted' AND T1.isTextless = 0	card_games
SELECT DISTINCT r.text FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.name = 'Condemn'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Restricted' AND T1.isStarter = 1	card_games
SELECT l.status FROM legalities l JOIN cards c ON l.uuid = c.uuid WHERE c.name = 'Cloudchaser Eagle'	card_games
SELECT DISTINCT type FROM cards WHERE name = 'Benalish Knight'	card_games
SELECT DISTINCT l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.name = 'Benalish Knight'	card_games
SELECT c.artist FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE f.language = 'Phyrexian'	card_games
SELECT CAST(SUM(CASE WHEN borderColor = 'borderless' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(id) FROM cards	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T2.language = 'German' AND T1.isReprint = 1	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T1.borderColor = 'borderless' AND T2.language = 'Russian'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'French' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 LEFT JOIN foreign_data AS T2 ON T1.uuid = T2.uuid WHERE T1.isStorySpotlight = 1	card_games
SELECT COUNT(id) FROM cards WHERE CAST(toughness AS INTEGER) = 99	card_games
SELECT DISTINCT name FROM cards WHERE artist = 'Aaron Boyd'	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'black' AND availability = 'mtgo'	card_games
SELECT id FROM cards WHERE convertedManaCost = 0	card_games
SELECT DISTINCT layout FROM cards WHERE keywords LIKE '%Flying%'	card_games
SELECT COUNT(id) FROM cards WHERE originalType = 'Summon - Angel' AND subtypes != 'Angel'	card_games
SELECT id FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT id FROM cards WHERE duelDeck = 'a'	card_games
SELECT edhrecRank FROM cards WHERE frameVersion = '2015'	card_games
SELECT DISTINCT c.artist FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE fd.language = 'Chinese Simplified'	card_games
SELECT DISTINCT c.name FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE c.availability = 'paper' AND f.language = 'Japanese'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.status = 'Banned' AND T1.borderColor = 'white'	card_games
SELECT l.uuid, f.language FROM legalities l JOIN foreign_data f ON l.uuid = f.uuid WHERE l.format = 'legacy'	card_games
SELECT TRIM(r.text) AS text FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.name = 'Beacon of Immortality'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 WHERE T1.frameVersion = 'future'	card_games
SELECT id, colors FROM cards WHERE setCode = 'OGW'	card_games
SELECT c.id, f.language FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE c.setCode = '10E' AND c.convertedManaCost = 5	card_games
SELECT c.id, r.date FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.originalType = 'Creature - Elf'	card_games
SELECT c.colors, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.id BETWEEN 1 AND 20	card_games
SELECT DISTINCT c.name FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE c.originalType = 'Artifact' AND c.colors = 'B'	card_games
SELECT DISTINCT c.name FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.rarity = 'uncommon' ORDER BY r.date ASC LIMIT 3	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'John Avon' AND cardKingdomFoilId IS NULL	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'white' AND cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'UDON' AND availability = 'mtgo' AND hand = '-1'	card_games
SELECT COUNT(id) FROM cards WHERE frameVersion = '1993' AND availability LIKE '%paper%' AND hasContentWarning = 1	card_games
SELECT manaCost FROM cards WHERE layout = 'normal' AND CAST(frameVersion AS INTEGER) = 2003 AND borderColor = 'black' AND availability = 'mtgo,paper'	card_games
SELECT manaCost FROM cards WHERE artist = 'Rob Alexander'	card_games
SELECT DISTINCT subtypes, supertypes FROM cards WHERE availability = 'arena'	card_games
SELECT c.setCode FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE fd.language = 'Spanish'	card_games
SELECT SUM(CASE WHEN isOnlineOnly = 1 THEN 1.0 ELSE 0 END) / COUNT(id) * 100 FROM cards WHERE frameEffects = 'legendary'	card_games
SELECT CAST(SUM(CASE WHEN isTextless = 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(id) FROM cards WHERE isStorySpotlight = 1	card_games
SELECT (SELECT CAST(SUM(CASE WHEN language = 'Spanish' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM foreign_data) AS percentage, name FROM foreign_data WHERE language = 'Spanish'	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.baseSetSize = 309	card_games
SELECT COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.block = 'Commander' AND T2.language = 'Portuguese (Brazil)'	card_games
SELECT DISTINCT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.types LIKE '%Creature%' AND l.status = 'Legal'	card_games
SELECT DISTINCT c.subtypes, c.supertypes FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE f.language = 'German' AND c.subtypes IS NOT NULL AND c.supertypes IS NOT NULL	card_games
SELECT r.text FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE (c.power IS NULL OR c.power = '*') AND r.text LIKE '%triggered ability%'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 JOIN legalities AS T2 ON T1.uuid = T2.uuid JOIN rulings AS T3 ON T1.uuid = T3.uuid WHERE T2.format = 'premodern' AND TRIM(T3.text) = 'This is a triggered mana ability.' AND T1.side IS NULL	card_games
SELECT c.id FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.artist = 'Erica Yang' AND l.format = 'pauper' AND c.availability = 'paper'	card_games
SELECT c.artist FROM cards c JOIN foreign_data f ON c.uuid = f.uuid WHERE TRIM(f.text) = 'Das perfekte Gegenmittel zu einer dichten Formation'	card_games
SELECT DISTINCT fd.name FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE fd.language = 'French' AND c.type LIKE '%Creature%' AND c.layout = 'normal' AND c.borderColor = 'black' AND c.artist = 'Matthew D. Wilson'	card_games
SELECT COUNT(DISTINCT T1.id) FROM cards AS T1 INNER JOIN rulings AS T2 ON T1.uuid = T2.uuid WHERE T1.rarity = 'rare' AND T2.date = '2007-02-01'	card_games
SELECT language FROM set_translations WHERE setCode = 'DIS'	card_games
SELECT CAST(SUM(CASE WHEN T1.hasContentWarning = 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 INNER JOIN legalities AS T2 ON T1.uuid = T2.uuid WHERE T2.format = 'commander' AND T2.status = 'Legal'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'French' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards T1 LEFT JOIN foreign_data T2 ON T1.uuid = T2.uuid WHERE T1.power IS NULL OR T1.power = '*'	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'Japanese' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.type = 'expansion'	card_games
SELECT DISTINCT availability FROM cards WHERE artist = 'Daren Bader'	card_games
SELECT COUNT(id) FROM cards WHERE borderColor = 'borderless' AND edhrecRank > 12000	card_games
SELECT COUNT(id) FROM cards WHERE isOversized = 1 AND isReprint = 1 AND isPromo = 1	card_games
SELECT name FROM cards WHERE (power IS NULL OR power = '*') AND promoTypes = 'arenaleague' ORDER BY name ASC LIMIT 3	card_games
SELECT language FROM foreign_data WHERE multiverseid = 149934	card_games
SELECT cardKingdomFoilId, cardKingdomId FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL ORDER BY cardKingdomFoilId LIMIT 3	card_games
SELECT CAST(SUM(CASE WHEN isTextless = 1 AND layout = 'normal' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM cards	card_games
SELECT id FROM cards WHERE side IS NULL AND subtypes LIKE '%Angel%' AND subtypes LIKE '%Wizard%'	card_games
SELECT name FROM sets WHERE mtgoCode IS NULL OR mtgoCode = '' ORDER BY name LIMIT 3	card_games
SELECT st.language FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE s.mcmName = 'Archenemy' AND s.code = 'ARC'	card_games
SELECT s.name, st.translation FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.id = 5	card_games
SELECT st.language, s.type FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.id = 206	card_games
SELECT DISTINCT s.name, s.id FROM sets s JOIN cards c ON s.code = c.setCode JOIN foreign_data fd ON c.uuid = fd.uuid WHERE fd.language = 'Italian' AND s.block = 'Shadowmoor' ORDER BY s.name LIMIT 2	card_games
SELECT s.name, s.id FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.isForeignOnly = 0 AND s.isFoilOnly = 1 AND st.language = 'Japanese'	card_games
SELECT s.id FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.language = 'Russian' ORDER BY s.baseSetSize DESC LIMIT 1	card_games
SELECT CAST(SUM(CASE WHEN T2.language = 'Chinese Simplified' AND T1.isOnlineOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM cards AS T1 JOIN foreign_data AS T2 ON T1.uuid = T2.uuid	card_games
SELECT COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T2.language = 'Japanese' AND (T1.mtgoCode IS NULL OR T1.mtgoCode = '')	card_games
SELECT id FROM cards WHERE borderColor = 'black'	card_games
SELECT id FROM cards WHERE frameEffects = 'extendedart'	card_games
SELECT id FROM cards WHERE borderColor = 'black' AND isFullArt = 1	card_games
SELECT st.language FROM sets s LEFT JOIN set_translations st ON s.code = st.setCode WHERE s.id = 174	card_games
SELECT name FROM sets WHERE code = 'ALL'	card_games
SELECT DISTINCT language FROM foreign_data WHERE name = 'A Pedra Fellwar'	card_games
SELECT code AS setCode FROM sets WHERE releaseDate = '2007-07-13'	card_games
SELECT baseSetSize, code AS setCode FROM sets WHERE block IN ("Masques", "Mirage")	card_games
SELECT code AS setCode FROM sets WHERE type = 'expansion'	card_games
SELECT fd.name, fd.type FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'boros'	card_games
SELECT fd.language, fd.flavorText FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.watermark = 'colorpie'	card_games
SELECT CAST(SUM(CASE WHEN T1.convertedManaCost = 10 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id), 'Abyssal Horror' AS name FROM cards AS T1 WHERE T1.setCode IN ( SELECT DISTINCT T2.setCode FROM cards AS T2 WHERE T2.name = 'Abyssal Horror' )	card_games
SELECT code AS setCode FROM sets WHERE type = 'commander'	card_games
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
SELECT DISTINCT name FROM cards WHERE frameVersion = '2003' ORDER BY convertedManaCost DESC LIMIT 3	card_games
SELECT DISTINCT st.translation FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Ancestor''s Chosen' AND st.language = 'Italian'	card_games
SELECT COUNT(DISTINCT st.translation) FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Angel of Mercy'	card_games
SELECT DISTINCT c.name FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE st.translation = 'Hauptset Zehnte Edition'	card_games
SELECT IIF(SUM(CASE WHEN language = 'Korean' AND text IS NOT NULL THEN 1 ELSE 0 END) > 0, 'YES', 'NO') FROM foreign_data WHERE name = 'Ancestor''s Chosen'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 INNER JOIN set_translations AS T2 ON T1.setCode = T2.setCode WHERE T2.translation = 'Hauptset Zehnte Edition' AND T1.artist = 'Adam Rex'	card_games
SELECT s.baseSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Hauptset Zehnte Edition'	card_games
SELECT st.translation FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.name = 'Eighth Edition' AND st.language = 'Chinese Simplified'	card_games
SELECT IIF(T2.mtgoCode IS NOT NULL, 'YES', 'NO') FROM cards AS T1 INNER JOIN sets AS T2 ON T1.setCode = T2.code WHERE T1.name = 'Angel of Mercy'	card_games
SELECT DISTINCT s.releaseDate FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Ancestor''s Chosen'	card_games
SELECT s.type FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE st.translation = 'Hauptset Zehnte Edition'	card_games
SELECT COUNT(DISTINCT T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.block = 'Ice Age' AND T2.language = 'Italian' AND T2.translation IS NOT NULL	card_games
SELECT IIF(sets.isForeignOnly = 1, 'YES', 'NO') FROM cards JOIN sets ON cards.setCode = sets.code WHERE cards.name = 'Adarkar Valkyrie' LIMIT 1	card_games
SELECT COUNT(T1.id) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T2.language = 'Italian' AND T1.baseSetSize < 100	card_games
SELECT SUM(CASE WHEN T1.borderColor = 'black' THEN 1 ELSE 0 END) FROM cards AS T1 JOIN sets AS T2 ON T1.setCode = T2.code WHERE T2.name = 'Coldsnap'	card_games
SELECT c.name FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap' ORDER BY c.convertedManaCost DESC LIMIT 1	card_games
SELECT DISTINCT c.artist FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap' AND c.artist IN ('Jeremy Jarvis', 'Aaron Miller', 'Chippy')	card_games
SELECT name FROM cards WHERE setCode = 'CSP' AND number = '4'	card_games
SELECT SUM(CASE WHEN T1.power LIKE '*' OR T1.power IS NULL THEN 1 ELSE 0 END) FROM cards AS T1 JOIN sets AS T2 ON T1.setCode = T2.code WHERE T2.name = 'Coldsnap' AND T1.convertedManaCost > 5	card_games
SELECT fd.flavorText FROM foreign_data fd JOIN cards c ON fd.uuid = c.uuid WHERE c.name = 'Ancestor''s Chosen' AND fd.language = 'Italian'	card_games
SELECT language FROM foreign_data WHERE name = 'Ancestor''s Chosen' AND flavorText IS NOT NULL AND TRIM(flavorText) != ''	card_games
SELECT fd.type FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.name = 'Ancestor''s Chosen' AND fd.language = 'German'	card_games
SELECT fd.text FROM cards c JOIN sets s ON c.setCode = s.code JOIN foreign_data fd ON c.uuid = fd.uuid WHERE s.name = 'Coldsnap' AND fd.language = 'Italian'	card_games
SELECT fd.name FROM cards c JOIN foreign_data fd ON c.uuid = fd.uuid WHERE c.setCode = 'CSP' AND fd.language = 'Italian' AND c.convertedManaCost = ( SELECT MAX(convertedManaCost) FROM cards WHERE setCode = 'CSP' )	card_games
SELECT DISTINCT rulings.date FROM rulings JOIN cards ON rulings.uuid = cards.uuid WHERE cards.name = 'Reminisce'	card_games
SELECT CAST(SUM(CASE WHEN c.convertedManaCost = 7 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(c.id) FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Coldsnap'	card_games
SELECT CAST(SUM(CASE WHEN T1.cardKingdomFoilId IS NOT NULL AND T1.cardKingdomId IS NOT NULL THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.id) FROM cards AS T1 JOIN sets AS T2 ON T1.setCode = T2.code WHERE T2.name = 'Coldsnap'	card_games
SELECT code FROM sets WHERE releaseDate = '2017-07-14'	card_games
SELECT keyruneCode FROM sets WHERE code = 'PKHC'	card_games
SELECT mcmId FROM sets WHERE code = 'SS2'	card_games
SELECT mcmName FROM sets WHERE releaseDate = '2017-06-09'	card_games
SELECT type FROM sets WHERE name = 'From the Vault: Lore'	card_games
SELECT parentCode FROM sets WHERE name = 'Commander 2014 Oversized'	card_games
SELECT r.text, CASE WHEN c.hasContentWarning = 1 THEN 'YES' ELSE 'NO' END FROM cards c JOIN rulings r ON c.uuid = r.uuid WHERE c.artist = 'Jim Pavelec'	card_games
SELECT s.releaseDate FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Evacuation'	card_games
SELECT s.baseSetSize FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Rinascita di Alara'	card_games
SELECT s.type FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Huitième édition'	card_games
SELECT s.name AS translation FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Tendo Ice Bridge' LIMIT 1	card_games
SELECT COUNT(DISTINCT T2.translation) FROM sets AS T1 INNER JOIN set_translations AS T2 ON T1.code = T2.setCode WHERE T1.name = 'Tenth Edition' AND T2.translation IS NOT NULL	card_games
SELECT DISTINCT st.translation FROM cards c JOIN set_translations st ON c.setCode = st.setCode WHERE c.name = 'Fellwar Stone' AND st.language = 'Japanese' AND st.translation IS NOT NULL	card_games
SELECT c.name FROM cards c JOIN sets s ON c.setCode = s.code WHERE s.name = 'Journey into Nyx Hero''s Path' ORDER BY c.convertedManaCost DESC LIMIT 1	card_games
SELECT s.releaseDate FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE st.translation = 'Ola de frío'	card_games
SELECT s.type FROM cards c JOIN sets s ON c.setCode = s.code WHERE c.name = 'Samite Pilgrim'	card_games
SELECT COUNT(cards.id) FROM cards JOIN sets ON cards.setCode = sets.code WHERE sets.name = 'World Championship Decks 2004' AND cards.convertedManaCost = 3	card_games
SELECT st.translation FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE s.name = 'Mirrodin' AND st.language = 'Chinese Simplified'	card_games
SELECT CAST(SUM(CASE WHEN s.isNonFoilOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.id) FROM foreign_data f JOIN cards c ON f.uuid = c.uuid JOIN sets s ON c.setCode = s.code WHERE f.language = 'Japanese'	card_games
SELECT CAST(SUM(CASE WHEN s.isOnlineOnly = 1 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(s.id) FROM set_translations st JOIN sets s ON st.setCode = s.code WHERE st.language = 'Portuguese (Brazil)'	card_games
SELECT DISTINCT availability FROM cards WHERE artist = 'Aleksi Briclot' AND isTextless = 1	card_games
SELECT id FROM sets ORDER BY baseSetSize DESC LIMIT 1	card_games
SELECT artist FROM cards WHERE side IS NULL ORDER BY convertedManaCost DESC LIMIT 1	card_games
SELECT frameEffects FROM cards WHERE cardKingdomFoilId IS NOT NULL AND cardKingdomId IS NOT NULL AND frameEffects IS NOT NULL GROUP BY frameEffects ORDER BY COUNT(*) DESC LIMIT 1	card_games
SELECT SUM(CASE WHEN power = '*' OR power IS NULL THEN 1 ELSE 0 END) FROM cards WHERE duelDeck = 'a' AND hasFoil = 0	card_games
SELECT id FROM sets WHERE type = 'commander' ORDER BY totalSetSize DESC LIMIT 1	card_games
SELECT DISTINCT c.name FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE l.format = 'duel' ORDER BY c.convertedManaCost DESC LIMIT 10	card_games
WITH oldest_mythic AS (SELECT MIN(originalReleaseDate) as min_date FROM cards WHERE rarity = 'mythic') SELECT c.originalReleaseDate, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid JOIN oldest_mythic om ON c.originalReleaseDate = om.min_date WHERE c.rarity = 'mythic' AND l.status = 'Legal'	card_games
SELECT COUNT(T3.id) FROM cards AS T3 INNER JOIN foreign_data AS T4 ON T3.uuid = T4.uuid WHERE T3.artist = 'Volkan Baǵa' AND T4.language = 'French'	card_games
SELECT COUNT(T1.id) FROM cards AS T1 WHERE T1.rarity = 'rare' AND T1.types = 'Enchantment' AND T1.name = 'Abundance' AND NOT EXISTS ( SELECT 1 FROM legalities AS T2 WHERE T2.uuid = T1.uuid AND T2.status != 'Legal' )	card_games
SELECT l.format, c.name FROM legalities l JOIN cards c ON l.uuid = c.uuid WHERE l.status = 'Banned' AND l.format = 'legacy' ORDER BY c.name	card_games
SELECT st.language FROM sets s JOIN set_translations st ON s.code = st.setCode WHERE s.name = 'Battlebond'	card_games
WITH artist_counts AS ( SELECT artist, COUNT(*) as card_count FROM cards WHERE artist IS NOT NULL GROUP BY artist ), min_count AS ( SELECT MIN(card_count) as min_val FROM artist_counts ), min_artists AS ( SELECT artist FROM artist_counts WHERE card_count = (SELECT min_val FROM min_count) ) SELECT c.artist, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.artist IN (SELECT artist FROM min_artists) ORDER BY c.artist, l.format	card_games
SELECT l.status FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.frameVersion = '1997' AND c.artist = 'D. Alexander Gregory' AND c.hasContentWarning = 1 AND l.format = 'legacy'	card_games
SELECT DISTINCT c.name, l.format FROM cards c JOIN legalities l ON c.uuid = l.uuid WHERE c.edhrecRank = 1 AND l.status = 'Banned'	card_games
SELECT (CAST(SUM(T1.id) AS REAL) / COUNT(T1.id)) / 4, ( SELECT language FROM foreign_data WHERE language IS NOT NULL AND language != '' GROUP BY language ORDER BY COUNT(*) DESC LIMIT 1 ) AS language FROM sets T1 WHERE T1.releaseDate BETWEEN '2012-01-01' AND '2015-12-31'	card_games
SELECT DISTINCT artist FROM cards WHERE BorderColor = 'black' AND availability = 'arena'	card_games
SELECT uuid FROM legalities WHERE format = 'oldschool' AND (status = 'Banned' OR status = 'Restricted')	card_games
SELECT COUNT(id) FROM cards WHERE artist = 'Matthew D. Wilson' AND availability = 'paper'	card_games
SELECT TRIM(r.text) AS text FROM rulings r JOIN cards c ON r.uuid = c.uuid WHERE c.artist = 'Kev Walker' ORDER BY r.date DESC	card_games
SELECT c.name, CASE WHEN l.status = 'Legal' THEN l.format ELSE NULL END FROM cards c JOIN sets s ON c.setCode = s.code LEFT JOIN legalities l ON c.uuid = l.uuid WHERE s.name = 'Hour of Devastation' ORDER BY c.name, l.format	card_games
SELECT s.name FROM sets s WHERE s.code IN ( SELECT st.setCode FROM set_translations st WHERE st.language = 'Korean' ) AND s.code NOT IN ( SELECT st.setCode FROM set_translations st WHERE st.language = 'Japanese' )	card_games
SELECT DISTINCT T1.frameVersion, T1.name, IIF(T2.status = 'Banned', T1.name, 'NO') FROM cards T1 LEFT JOIN legalities T2 ON T1.uuid = T2.uuid WHERE T1.artist = 'Allen Williams'	card_games
SELECT DisplayName FROM users WHERE TRIM(DisplayName) IN ('Harlan', 'Jarrod Dixon') ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users WHERE STRFTIME('%Y', CreationDate) = '2011'	codebase_community
SELECT COUNT(Id) FROM users WHERE LastAccessDate > '2014-09-01'	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users ORDER BY Views DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE UpVotes > 100 AND DownVotes > 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Views > 10 AND STRFTIME('%Y', CreationDate) > '2013'	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie' AND p.Title IS NOT NULL	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(p.Title) = 'Eliciting priors from experts'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie' ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.FavoriteCount IS NOT NULL ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT SUM(T1.CommentCount) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie'	codebase_community
SELECT MAX(p.AnswerCount) FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE u.DisplayName = 'csgillespie'	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(p.Title) = 'Examples for teaching: Correlation does not mean causation'	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie' AND T1.ParentId IS NULL	codebase_community
SELECT DISTINCT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ClosedDate IS NOT NULL	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T2.Age > 65 AND T1.Score >= 20	codebase_community
SELECT TRIM(u.Location) AS Location FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(p.Title) = 'Eliciting priors from experts'	codebase_community
SELECT p.Body FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id WHERE t.TagName = 'bayesian'	codebase_community
SELECT p.Body FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id ORDER BY t.Count DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'csgillespie'	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie' AND STRFTIME('%Y', T1.Date) = '2011'	codebase_community
SELECT u.DisplayName FROM users u JOIN badges b ON u.Id = b.UserId GROUP BY u.Id, u.DisplayName ORDER BY COUNT(b.Id) DESC LIMIT 1	codebase_community
SELECT AVG(T1.Score) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'csgillespie'	codebase_community
SELECT CAST(COUNT(T1.Id) AS REAL) / COUNT(DISTINCT T2.DisplayName) FROM badges AS T1 JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.Views > 200	codebase_community
SELECT CAST(SUM(IIF(T2.Age > 65, 1, 0)) AS REAL) * 100 / COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T1.Score > 5	codebase_community
SELECT COUNT(Id) FROM votes WHERE UserId = 58 AND CreationDate = '2010-07-19'	codebase_community
SELECT CreationDate FROM votes GROUP BY CreationDate ORDER BY COUNT(Id) DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Revival'	codebase_community
SELECT p.Title FROM comments c JOIN posts p ON c.PostId = p.Id ORDER BY c.Score DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM comments AS T1 JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T2.ViewCount = 1910	codebase_community
SELECT p.FavoriteCount FROM comments c JOIN posts p ON c.PostId = p.Id WHERE c.UserId = 3025 AND c.CreationDate = '2014-04-23 20:29:39'	codebase_community
SELECT c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE p.ParentId = 107829 AND p.CommentCount = 1	codebase_community
SELECT IIF(p."ClosedDate" IS NULL, 'not well-finished', 'well-finished') AS resylt FROM comments c JOIN posts p ON c."PostId" = p."Id" WHERE c."UserId" = 23853 AND c."CreationDate" = '2013-07-12 09:08:18.0'	codebase_community
SELECT u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 65041	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Tiago Pasqualini'	codebase_community
SELECT u.DisplayName FROM votes v JOIN users u ON v.UserId = u.Id WHERE v.Id = 6347	codebase_community
SELECT COUNT(T1.Id) FROM votes AS T1 INNER JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T2.Title LIKE '%data visualization%'	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'DatEpicCoderGuyWhoPrograms'	codebase_community
SELECT CAST((SELECT COUNT(Id) FROM posts WHERE OwnerUserId = 24) AS REAL) / (SELECT COUNT(DISTINCT Id) FROM votes WHERE UserId = 24) AS "CAST(COUNT(T2.Id) AS REAL) / COUNT(DISTINCT T1.Id)"	codebase_community
SELECT ViewCount FROM posts WHERE TRIM(Title) = 'Integration of Weka and/or RapidMiner into Informatica PowerCenter/Developer'	codebase_community
SELECT Text FROM comments WHERE Score = 17	codebase_community
SELECT TRIM("DisplayName") AS DisplayName FROM "users" WHERE "WebsiteUrl" = 'http://stackoverflow.com'	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'SilentGhost'	codebase_community
SELECT u.DisplayName FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(c.Text) = 'thank you user93!'	codebase_community
SELECT c.Text FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(u.DisplayName) = 'A Lion'	codebase_community
SELECT u.DisplayName, u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Title = 'Understanding what Dassault iSight is doing?'	codebase_community
SELECT c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE TRIM(p.Title) = 'How does gentle boosting differ from AdaBoost?'	codebase_community
SELECT DISTINCT TRIM(u.DisplayName) AS DisplayName FROM users u JOIN badges b ON u.Id = b.UserId WHERE b.Name = 'Necromancer' LIMIT 10	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(p.Title) = 'Open source tools for visualizing multi-dimensional data?'	codebase_community
SELECT p.Title FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(u.DisplayName) = 'Vebjorn Ljosa'	codebase_community
SELECT SUM(p.Score), u.WebsiteUrl FROM posts p JOIN users u ON p.LastEditorUserId = u.Id WHERE TRIM(u.DisplayName) = 'Yevgeny'	codebase_community
SELECT DISTINCT c.Text AS Comment FROM posts p JOIN postHistory ph ON p.Id = ph.PostId JOIN comments c ON ph.UserId = c.UserId WHERE TRIM(p.Title) = 'Why square the difference instead of taking the absolute value in standard deviation?'	codebase_community
SELECT SUM(v.BountyAmount) FROM posts p JOIN votes v ON p.Id = v.PostId WHERE LOWER(p.Title) LIKE '%data%' AND v.BountyAmount IS NOT NULL	codebase_community
SELECT u.DisplayName, p.Title FROM votes v JOIN posts p ON v.PostId = p.Id JOIN users u ON v.UserId = u.Id WHERE v.BountyAmount = 50 AND p.Title LIKE '%variance%'	codebase_community
SELECT (SELECT AVG(ViewCount) FROM posts WHERE Tags LIKE '%<humor>%') AS "AVG(T2.ViewCount)", Title, c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE p.Tags LIKE '%<humor>%'	codebase_community
SELECT COUNT(Id) FROM comments WHERE UserId = 13	codebase_community
SELECT Id FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT Id FROM users ORDER BY Views ASC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Supporter' AND STRFTIME('%Y', Date) = '2011'	codebase_community
SELECT COUNT(UserId) FROM (SELECT UserId FROM badges GROUP BY UserId HAVING COUNT(Name) > 5)	codebase_community
SELECT COUNT(DISTINCT T1.Id) FROM users AS T1 WHERE TRIM(T1.Location) = 'New York' AND EXISTS ( SELECT 1 FROM badges b1 WHERE b1.UserId = T1.Id AND b1.Name = 'Supporter' ) AND EXISTS ( SELECT 1 FROM badges b2 WHERE b2.UserId = T1.Id AND b2.Name = 'Teacher' )	codebase_community
SELECT u.Id, u.Reputation FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.Id = 1	codebase_community
SELECT DISTINCT u.Id AS UserId FROM users u JOIN postHistory ph ON u.Id = ph.UserId WHERE u.Views >= 1000 GROUP BY u.Id, ph.PostId HAVING COUNT(*) = 1	codebase_community
SELECT b.Name FROM badges b JOIN ( SELECT UserId FROM comments WHERE UserId IS NOT NULL GROUP BY UserId ORDER BY COUNT(Id) DESC LIMIT 1 ) top_commenter ON b.UserId = top_commenter.UserId	codebase_community
SELECT COUNT(T1.Id) FROM users AS T1 INNER JOIN badges AS T2 ON T1.Id = T2.UserId WHERE TRIM(T1.Location) = 'India' AND T2.Name = 'Teacher'	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', Date) = '2010', 1, 0)) AS REAL) * 100 / COUNT(Id) - CAST(SUM(IIF(STRFTIME('%Y', Date) = '2011', 1, 0)) AS REAL) * 100 / COUNT(Id) FROM badges WHERE Name = 'Student'	codebase_community
SELECT DISTINCT ph.PostHistoryTypeId, (SELECT COUNT(DISTINCT UserId) FROM comments WHERE PostId = 3720 AND UserId IS NOT NULL) AS NumberOfUsers FROM postHistory ph WHERE ph.PostId = 3720	codebase_community
SELECT p.ViewCount FROM postLinks pl JOIN posts p ON pl.RelatedPostId = p.Id WHERE pl.PostId = 61217	codebase_community
SELECT p.Score, pl.LinkTypeId FROM posts p JOIN postLinks pl ON p.Id = pl.PostId OR p.Id = pl.RelatedPostId WHERE p.Id = 395	codebase_community
SELECT Id AS PostId, OwnerUserId AS UserId FROM posts WHERE Score > 60	codebase_community
SELECT SUM(DISTINCT "FavoriteCount") FROM "posts" WHERE "OwnerUserId" = 686 AND STRFTIME('%Y', "CreaionDate") = '2011'	codebase_community
SELECT AVG(T1.UpVotes), AVG(T1.Age) FROM users AS T1 WHERE T1.Id IN ( SELECT T2.OwnerUserId FROM posts AS T2 WHERE T2.OwnerUserId IS NOT NULL GROUP BY T2.OwnerUserId HAVING COUNT(T2.Id) > 10 )	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Announcer'	codebase_community
SELECT Name FROM badges WHERE Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT COUNT(Id) FROM comments WHERE Score > 60	codebase_community
SELECT Text FROM comments WHERE CreationDate = '2010-07-19 19:16:14.0'	codebase_community
SELECT COUNT(Id) FROM posts WHERE Score = 10	codebase_community
SELECT DISTINCT b.Name AS name FROM badges b JOIN users u ON b.UserId = u.Id WHERE u.Reputation = (SELECT MAX(Reputation) FROM users)	codebase_community
SELECT u.Reputation FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Pierre'	codebase_community
SELECT b.Date FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.Location) = 'Rochester, NY'	codebase_community
SELECT CAST(COUNT(T1.Id) AS REAL) * 100 / (SELECT COUNT(Id) FROM users) FROM badges AS T1 WHERE T1.Name = 'Teacher'	codebase_community
SELECT CAST(SUM(IIF(T2.Age BETWEEN 13 AND 18, 1, 0)) AS REAL) * 100 / COUNT(T1.Id) FROM badges AS T1 JOIN users AS T2 ON T1.UserId = T2.Id WHERE T1.Name = 'Organizer'	codebase_community
SELECT comments.Score FROM comments JOIN posts ON comments.PostId = posts.Id WHERE posts.CreaionDate = '2010-07-19 19:19:56.0'	codebase_community
SELECT TRIM(comments.Text) AS Text FROM comments JOIN posts ON comments.PostId = posts.Id WHERE posts.CreaionDate = '2010-07-19 19:37:33'	codebase_community
SELECT DISTINCT u.Age FROM users u JOIN badges b ON u.Id = b.UserId WHERE TRIM(u.Location) = 'Vienna, Austria'	codebase_community
SELECT COUNT(b.Id) FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'Supporter' AND u.Age BETWEEN 19 AND 65	codebase_community
SELECT u.Views FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Date = '2010-07-19 19:39:08.0'	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE u.Reputation = (SELECT MIN(Reputation) FROM users WHERE Reputation IS NOT NULL)	codebase_community
SELECT DISTINCT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE u.DisplayName = 'Sharpie'	codebase_community
SELECT COUNT(T1.Id) FROM badges AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.Age > 65 AND T1.Name = 'Supporter'	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users WHERE Id = 30	codebase_community
SELECT COUNT(Id) FROM users WHERE TRIM(Location) = 'New York'	codebase_community
SELECT COUNT(Id) FROM votes WHERE strftime('%Y', CreationDate) = '2010'	codebase_community
SELECT COUNT(Id) FROM users WHERE Age BETWEEN 19 AND 65	codebase_community
SELECT "Id", TRIM("DisplayName") AS "DisplayName" FROM "users" ORDER BY "Views" DESC LIMIT 1	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', CreationDate) = '2010', 1, 0)) AS REAL) / SUM(IIF(STRFTIME('%Y', CreationDate) = '2011', 1, 0)) FROM votes	codebase_community
SELECT TRIM(p.Tags) AS Tags FROM users u JOIN posts p ON u.Id = p.OwnerUserId WHERE TRIM(u.DisplayName) = 'John Salvatier' AND p.Tags IS NOT NULL	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T2.DisplayName = 'Daniel Vassallo'	codebase_community
SELECT COUNT(T1.Id) FROM votes AS T1 INNER JOIN users AS T2 ON T1.UserId = T2.Id WHERE T2.DisplayName = 'Harlan'	codebase_community
SELECT p.Id AS PostId FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'slashnick' ORDER BY p.AnswerCount DESC LIMIT 1	codebase_community
SELECT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE u.DisplayName IN ('Harvey Motulsky', 'Noah Snyder') ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE T2.DisplayName = 'Matt Parker' AND T1.Id > 4	codebase_community
SELECT COUNT(T3.Id) FROM users AS T1 JOIN posts AS T2 ON T1.Id = T2.OwnerUserId JOIN comments AS T3 ON T2.Id = T3.PostId WHERE TRIM(T1.DisplayName) = 'Neil McGuigan' AND T3.Score < 60	codebase_community
SELECT p.Tags FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Mark Meckes' AND p.CommentCount = 0 AND p.Tags IS NOT NULL	codebase_community
SELECT DISTINCT u.DisplayName FROM users u JOIN badges b ON u.Id = b.UserId WHERE b.Name = 'Organizer'	codebase_community
SELECT CAST(COUNT(CASE WHEN p.Tags LIKE '%<r>%' THEN 1 END) AS REAL) * 100 / COUNT(*) AS percentage FROM posts p WHERE p.OwnerUserId = -1	codebase_community
SELECT SUM(CASE WHEN u.DisplayName = 'Mornington' THEN p.ViewCount ELSE 0 END) - SUM(CASE WHEN u.DisplayName = 'Amos' THEN p.ViewCount ELSE 0 END) AS diff FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE u.DisplayName IN ('Mornington', 'Amos') AND p.ViewCount IS NOT NULL	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Commentator' AND STRFTIME('%Y', Date) = '2014'	codebase_community
SELECT COUNT(Id) FROM posts WHERE CreaionDate BETWEEN '2010-07-21 00:00:00' AND '2010-07-21 23:59:59'	codebase_community
SELECT TRIM(DisplayName) AS DisplayName, Age FROM users WHERE Views = (SELECT MAX(Views) FROM users)	codebase_community
SELECT LastEditDate, LastEditorUserId FROM posts WHERE TRIM(Title) = 'Detecting a given face in a database of facial images'	codebase_community
SELECT COUNT(Id) FROM comments WHERE UserId = 13 AND Score < 60	codebase_community
SELECT p.Title, c.UserDisplayName FROM comments c JOIN posts p ON c.PostId = p.Id WHERE c.Score > 60	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE STRFTIME('%Y', b.Date) = '2011' AND TRIM(u.Location) = 'North Pole'	codebase_community
SELECT u.DisplayName, u.WebsiteUrl FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.FavoriteCount > 150	codebase_community
SELECT ph.Id, p.LastEditDate FROM postHistory ph JOIN posts p ON ph.PostId = p.Id WHERE TRIM(p.Title) = 'What is the best introductory Bayesian statistics textbook?'	codebase_community
SELECT u.LastAccessDate, TRIM(u.Location) AS Location FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'outliers'	codebase_community
SELECT p2."Title" FROM "posts" p1 JOIN "postLinks" pl ON p1."Id" = pl."PostId" JOIN "posts" p2 ON pl."RelatedPostId" = p2."Id" WHERE TRIM(p1."Title") = 'How to tell if something happened in a data set which monitors a value over time'	codebase_community
SELECT p.Id AS PostId, b.Name FROM posts p JOIN badges b ON p.OwnerUserId = b.UserId WHERE TRIM(p.OwnerDisplayName) = 'Samuel' AND STRFTIME('%Y', p.CreaionDate) = '2013' AND STRFTIME('%Y', b.Date) = '2013'	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ViewCount IS NOT NULL ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT u.DisplayName, u.Location FROM tags t JOIN posts p ON t.ExcerptPostId = p.Id JOIN users u ON p.OwnerUserId = u.Id WHERE t.TagName = 'hypothesis-testing'	codebase_community
SELECT p2.Title, pl.LinkTypeId FROM posts p1 JOIN postLinks pl ON p1.Id = pl.PostId JOIN posts p2 ON pl.RelatedPostId = p2.Id WHERE p1.Title = 'What are principal component scores?'	codebase_community
SELECT "users"."DisplayName" AS "DisplayName" FROM "posts" JOIN "users" ON "posts"."OwnerUserId" = "users"."Id" WHERE "posts"."ParentId" IS NOT NULL ORDER BY "posts"."Score" DESC LIMIT 1	codebase_community
SELECT u.DisplayName, u.WebsiteUrl FROM votes v JOIN users u ON v.UserId = u.Id WHERE v.VoteTypeId = 8 ORDER BY v.BountyAmount DESC LIMIT 1	codebase_community
SELECT TRIM("Title") AS Title FROM posts WHERE "ViewCount" IS NOT NULL AND "Title" IS NOT NULL ORDER BY "ViewCount" DESC LIMIT 5	codebase_community
SELECT COUNT(Id) FROM tags WHERE Count BETWEEN 5000 AND 7000	codebase_community
SELECT OwnerUserId FROM posts WHERE FavoriteCount IS NOT NULL ORDER BY FavoriteCount DESC LIMIT 1	codebase_community
SELECT Age FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN votes AS T2 ON T1.Id = T2.PostId WHERE STRFTIME('%Y', T2.CreationDate) = '2011' AND T2.BountyAmount = 50	codebase_community
SELECT Id FROM users ORDER BY Age ASC LIMIT 1	codebase_community
SELECT SUM(Score) FROM posts WHERE LasActivityDate LIKE '2010-07-19%'	codebase_community
SELECT CAST(COUNT(T1.Id) AS REAL) / 12 FROM postLinks AS T1 JOIN posts AS T2 ON T1.PostId = T2.Id WHERE STRFTIME('%Y', T1.CreationDate) = '2010' AND T2.AnswerCount <= 2	codebase_community
SELECT p.Id FROM votes v JOIN posts p ON v.PostId = p.Id WHERE v.UserId = 1465 ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT p.Title FROM postLinks pl JOIN posts p ON pl.PostId = p.Id ORDER BY pl.CreationDate LIMIT 1	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM badges b JOIN users u ON b.UserId = u.Id GROUP BY b.UserId, TRIM(u.DisplayName) ORDER BY COUNT(b.Name) DESC LIMIT 1	codebase_community
SELECT MIN(v."CreationDate") AS "CreationDate" FROM "votes" v JOIN "users" u ON v."UserId" = u."Id" WHERE TRIM(u."DisplayName") = 'chl'	codebase_community
SELECT p.CreaionDate FROM users u JOIN posts p ON u.Id = p.OwnerUserId WHERE u.Age IS NOT NULL ORDER BY u.Age ASC, p.CreaionDate ASC LIMIT 1	codebase_community
SELECT TRIM(u.DisplayName) AS DisplayName FROM badges b JOIN users u ON b.UserId = u.Id WHERE b.Name = 'Autobiographer' ORDER BY b.Date ASC LIMIT 1	codebase_community
SELECT COUNT(T1.Id) FROM users AS T1 JOIN posts AS T2 ON T1.Id = T2.OwnerUserId WHERE TRIM(T1.Location) = 'United Kingdom' AND T2.FavoriteCount >= 4	codebase_community
SELECT AVG(v."PostId") FROM votes v JOIN users u ON v."UserId" = u."Id" WHERE u."Age" = (SELECT MAX("Age") FROM users WHERE "Age" IS NOT NULL)	codebase_community
SELECT TRIM(DisplayName) AS DisplayName FROM users ORDER BY Reputation DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Reputation > 2000 AND Views > 1000	codebase_community
SELECT DisplayName FROM users WHERE Age BETWEEN 19 AND 65	codebase_community
SELECT COUNT(T1.Id) FROM posts AS T1 INNER JOIN users AS T2 ON T1.OwnerUserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Jay Stevens' AND STRFTIME('%Y', T1.CreaionDate) = '2010'	codebase_community
SELECT p.Id, p.Title FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE TRIM(u.DisplayName) = 'Harvey Motulsky' ORDER BY p.ViewCount DESC LIMIT 1	codebase_community
SELECT Id, TRIM(Title) AS Title FROM posts ORDER BY Score DESC LIMIT 1	codebase_community
SELECT AVG(T2.Score) FROM users AS T1 INNER JOIN posts AS T2 ON T1.Id = T2.OwnerUserId WHERE TRIM(T1.DisplayName) = 'Stephen Turner'	codebase_community
SELECT DISTINCT u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE p.ViewCount > 20000 AND STRFTIME('%Y', p.CreaionDate) = '2011'	codebase_community
SELECT p.OwnerUserId, u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE STRFTIME('%Y', p.CreaionDate) = '2010' ORDER BY p.FavoriteCount DESC LIMIT 1	codebase_community
SELECT CAST(SUM(IIF(STRFTIME('%Y', posts.CreaionDate) = '2011' AND users.Reputation > 1000, 1, 0)) AS REAL) * 100 / COUNT(posts.Id) FROM posts INNER JOIN users ON users.Id = posts.OwnerUserId	codebase_community
SELECT CAST(COUNT(CASE WHEN Age BETWEEN 13 AND 18 THEN Id END) AS REAL) * 100 / COUNT(Id) AS percentage FROM users	codebase_community
SELECT p.ViewCount, u.DisplayName FROM posts p JOIN users u ON p.OwnerUserId = u.Id WHERE LOWER(TRIM(p.Title)) LIKE '%computer game datasets%'	codebase_community
SELECT Id FROM posts WHERE ViewCount > (SELECT AVG(ViewCount) FROM posts WHERE ViewCount IS NOT NULL)	codebase_community
SELECT COUNT(c.Id) FROM posts p JOIN comments c ON p.Id = c.PostId WHERE p.Score = (SELECT MAX(Score) FROM posts)	codebase_community
SELECT COUNT(Id) FROM posts WHERE ViewCount > 35000 AND CommentCount = 0	codebase_community
SELECT u.DisplayName, u.Location FROM postHistory ph JOIN users u ON ph.UserId = u.Id WHERE ph.PostId = 183 ORDER BY ph.CreationDate DESC LIMIT 1	codebase_community
SELECT b.Name FROM badges b JOIN users u ON b.UserId = u.Id WHERE TRIM(u.DisplayName) = 'Emmett' ORDER BY b.Date DESC LIMIT 1	codebase_community
SELECT COUNT(Id) FROM users WHERE Age BETWEEN 19 AND 65 AND UpVotes > 5000	codebase_community
SELECT julianday(T1.Date) - julianday(T2.CreationDate) AS "T1.Date - T2.CreationDate" FROM badges AS T1 JOIN users AS T2 ON T1.UserId = T2.Id WHERE TRIM(T2.DisplayName) = 'Zolomon'	codebase_community
WITH latest_user AS ( SELECT Id FROM users ORDER BY CreationDate DESC LIMIT 1 ) SELECT COUNT(p.Id) FROM posts p INNER JOIN comments c ON p.Id = c.PostId WHERE p.OwnerUserId = (SELECT Id FROM latest_user)	codebase_community
SELECT c.Text, u.DisplayName FROM comments c JOIN posts p ON c.PostId = p.Id JOIN users u ON c.UserId = u.Id WHERE TRIM(p.Title) = 'Analysing wind data with R' ORDER BY c.CreationDate DESC LIMIT 10	codebase_community
SELECT COUNT(Id) FROM badges WHERE Name = 'Citizen Patrol'	codebase_community
SELECT COUNT(Id) FROM posts WHERE Tags LIKE '%<careers>%'	codebase_community
SELECT Reputation, Views FROM users WHERE TRIM(DisplayName) = 'Jarrod Dixon'	codebase_community
SELECT (SELECT COUNT(*) FROM comments WHERE PostId = 13781) AS CommentCount, (SELECT COUNT(*) FROM posts WHERE ParentId = 13781 AND PostTypeId = 2) AS AnswerCount	codebase_community
SELECT CreationDate FROM users WHERE TRIM(DisplayName) = 'IrishStat'	codebase_community
SELECT COUNT(Id) FROM votes WHERE BountyAmount IS NOT NULL AND BountyAmount >= 30	codebase_community
SELECT CAST(SUM(CASE WHEN p.Score > 50 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(p.Id) FROM users u JOIN posts p ON u.Id = p.OwnerUserId WHERE u.Reputation = (SELECT MAX(Reputation) FROM users WHERE Reputation IS NOT NULL)	codebase_community
SELECT COUNT(Id) FROM posts WHERE Score < 20	codebase_community
SELECT COUNT(Id) FROM tags WHERE Id < 15 AND Count <= 20	codebase_community
SELECT ExcerptPostId, WikiPostId FROM tags WHERE TagName = 'sample'	codebase_community
SELECT u.Reputation, u.UpVotes FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(c.Text) LIKE 'fine, you win :%'	codebase_community
SELECT TRIM(c.Text) AS Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.Title LIKE '%linear regression%'	codebase_community
SELECT c.Text FROM comments c JOIN posts p ON c.PostId = p.Id WHERE p.ViewCount BETWEEN 100 AND 150 ORDER BY c.Score DESC LIMIT 1	codebase_community
SELECT u.CreationDate, u.Age FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Text LIKE '%http://%'	codebase_community
SELECT COUNT(T1.Id) FROM comments AS T1 INNER JOIN posts AS T2 ON T1.PostId = T2.Id WHERE T1.Score = 0 AND T2.ViewCount < 5	codebase_community
SELECT COUNT(c.Id) FROM posts p JOIN comments c ON p.Id = c.PostId WHERE p.CommentCount = 1 AND c.Score = 0	codebase_community
SELECT COUNT(DISTINCT u.Id) FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Score = 0 AND u.Age = 40	codebase_community
SELECT p.Id, c.Text FROM posts p JOIN comments c ON p.Id = c.PostId WHERE TRIM(p.Title) = 'Group differences on a five point Likert item'	codebase_community
SELECT u.UpVotes FROM comments c JOIN users u ON c.UserId = u.Id WHERE TRIM(c.Text) = 'R is also lazy evaluated.'	codebase_community
SELECT TRIM(c."Text") AS Text FROM comments c JOIN users u ON c."UserId" = u."Id" WHERE TRIM(u."DisplayName") = 'Harvey Motulsky'	codebase_community
SELECT DISTINCT u.DisplayName FROM comments c JOIN users u ON c.UserId = u.Id WHERE u.DownVotes = 0 AND c.Score BETWEEN 1 AND 5	codebase_community
SELECT CAST(COUNT(CASE WHEN u.UpVotes = 0 THEN 1 END) AS REAL) * 100 / COUNT(*) AS per FROM comments c JOIN users u ON c.UserId = u.Id WHERE c.Score BETWEEN 5 AND 10	codebase_community
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = '3-D Man'	superhero
SELECT COUNT(T1.hero_id) FROM hero_power AS T1 INNER JOIN superpower AS T2 ON T1.power_id = T2.id WHERE T2.power_name = 'Super Strength'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN hero_power AS T2 ON T1.id = T2.hero_id JOIN superpower AS T3 ON T2.power_id = T3.id WHERE T3.power_name = 'Super Strength' AND T1.height_cm > 200	superhero
SELECT s.full_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id GROUP BY s.id, s.full_name HAVING COUNT(hp.power_id) > 15	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id WHERE T2.colour = 'Blue'	superhero
SELECT colour.colour FROM superhero JOIN colour ON superhero.skin_colour_id = colour.id WHERE superhero.superhero_name = 'Apocalypse'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id JOIN hero_power AS T3 ON T1.id = T3.hero_id JOIN superpower AS T4 ON T3.power_id = T4.id WHERE T2.colour = 'Blue' AND T4.power_name = 'Agility'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour eye_colour ON s.eye_colour_id = eye_colour.id JOIN colour hair_colour ON s.hair_colour_id = hair_colour.id WHERE eye_colour.colour = 'Blue' AND hair_colour.colour = 'Blond'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT s.superhero_name, s.height_cm, ROW_NUMBER() OVER (ORDER BY s.height_cm DESC) AS HeightRank FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE p.publisher_name = 'Marvel Comics'	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name = 'Sauron'	superhero
SELECT c.colour AS EyeColor, COUNT(s.id) AS Count, RANK() OVER (ORDER BY COUNT(s.id) DESC) AS PopularityRank FROM superhero s JOIN publisher p ON s.publisher_id = p.id JOIN colour c ON s.eye_colour_id = c.id WHERE p.publisher_name = 'Marvel Comics' GROUP BY c.colour, c.id ORDER BY Count DESC	superhero
SELECT AVG(T1.height_cm) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT DISTINCT superhero.superhero_name FROM superhero JOIN publisher ON superhero.publisher_id = publisher.id JOIN hero_power ON superhero.id = hero_power.hero_id JOIN superpower ON hero_power.power_id = superpower.id WHERE publisher.publisher_name = 'Marvel Comics' AND superpower.power_name = 'Super Strength'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T2.publisher_name = 'DC Comics'	superhero
SELECT p.publisher_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id JOIN publisher p ON s.publisher_id = p.id WHERE a.attribute_name = 'Speed' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id JOIN publisher AS T3 ON T1.publisher_id = T3.id WHERE T2.colour = 'Gold' AND T3.publisher_name = 'Marvel Comics'	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name = 'Blue Beetle II'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN colour AS T2 ON T1.hair_colour_id = T2.id WHERE T2.colour = 'Blond'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Intelligence' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.superhero_name = 'Copycat'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Durability' AND ha.attribute_value < 50	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Death Touch'	superhero
SELECT COUNT(T1.id) FROM superhero T1 JOIN gender T2 ON T1.gender_id = T2.id JOIN hero_attribute T3 ON T1.id = T3.hero_id JOIN attribute T4 ON T3.attribute_id = T4.id WHERE T2.gender = 'Female' AND T4.attribute_name = 'Strength' AND T3.attribute_value = 100	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id GROUP BY s.id, s.superhero_name ORDER BY COUNT(hp.power_id) DESC LIMIT 1	superhero
SELECT COUNT(T1.superhero_name) FROM superhero AS T1 INNER JOIN race AS T2 ON T1.race_id = T2.id WHERE T2.race = 'Vampire'	superhero
SELECT (CAST(COUNT(*) AS REAL) * 100 / (SELECT COUNT(*) FROM superhero)), CAST(SUM(CASE WHEN p.publisher_name = 'Marvel Comics' THEN 1 ELSE 0 END) AS REAL) FROM superhero s JOIN alignment a ON s.alignment_id = a.id JOIN publisher p ON s.publisher_id = p.id WHERE a.alignment = 'Bad'	superhero
SELECT SUM(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.publisher_name = 'DC Comics' THEN 1 ELSE 0 END) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id	superhero
SELECT id FROM publisher WHERE publisher_name = 'Star Trek'	superhero
SELECT AVG(attribute_value) FROM hero_attribute	superhero
SELECT COUNT(id) FROM superhero WHERE full_name IS NULL	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.id = 75	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Deathlok'	superhero
SELECT AVG(T1.weight_kg) FROM superhero AS T1 INNER JOIN gender AS T2 ON T1.gender_id = T2.id WHERE T2.gender = 'Female'	superhero
SELECT sp.power_name FROM superhero s JOIN gender g ON s.gender_id = g.id JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE g.gender = 'Male' LIMIT 5	superhero
SELECT superhero.superhero_name FROM superhero JOIN race ON superhero.race_id = race.id WHERE race.race = 'Alien'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.height_cm BETWEEN 170 AND 190 AND c.colour = 'No Colour'	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE hp.hero_id = 56	superhero
SELECT s.full_name FROM superhero s JOIN race r ON s.race_id = r.id WHERE r.race = 'Demi-God' LIMIT 5	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN alignment AS T2 ON T1.alignment_id = T2.id WHERE T2.alignment = 'Bad'	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.weight_kg = 169	superhero
SELECT c.colour FROM superhero s JOIN race r ON s.race_id = r.id JOIN colour c ON s.hair_colour_id = c.id WHERE s.height_cm = 185 AND LOWER(r.race) = 'human'	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id ORDER BY s.weight_kg DESC LIMIT 1	superhero
SELECT CAST(COUNT(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T1.height_cm BETWEEN 150 AND 180	superhero
SELECT s.superhero_name FROM superhero s JOIN gender g ON s.gender_id = g.id WHERE g.gender = 'Male' AND s.weight_kg > (SELECT AVG(weight_kg) * 0.79 FROM superhero)	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id GROUP BY sp.power_name ORDER BY COUNT(*) DESC LIMIT 1	superhero
SELECT ha.attribute_value FROM hero_attribute ha JOIN superhero s ON ha.hero_id = s.id WHERE s.superhero_name = 'Abomination'	superhero
SELECT sp.power_name FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE hp.hero_id = 1	superhero
SELECT COUNT(T1.hero_id) FROM hero_power AS T1 INNER JOIN superpower AS T2 ON T1.power_id = T2.id WHERE T2.power_name = 'Stealth'	superhero
SELECT s.full_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Strength' ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT CAST(COUNT(*) AS REAL) / SUM(CASE WHEN T2.id = 1 THEN 1 ELSE 0 END) FROM superhero AS T1 JOIN colour AS T2 ON T1.skin_colour_id = T2.id	superhero
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
SELECT s.height_cm FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE c.colour = 'Amber'	superhero
SELECT s.superhero_name FROM superhero s JOIN colour eye ON s.eye_colour_id = eye.id JOIN colour hair ON s.hair_colour_id = hair.id WHERE eye.colour = 'Black' AND hair.colour = 'Black'	superhero
SELECT c2.colour FROM superhero s JOIN colour c1 ON s.skin_colour_id = c1.id JOIN colour c2 ON s.eye_colour_id = c2.id WHERE c1.colour = 'Gold'	superhero
SELECT s.full_name FROM superhero s JOIN race r ON s.race_id = r.id WHERE r.race = 'Vampire'	superhero
SELECT s.superhero_name FROM superhero s JOIN alignment a ON s.alignment_id = a.id WHERE a.alignment = 'Neutral'	superhero
SELECT COUNT(T1.hero_id) FROM hero_attribute AS T1 WHERE T1.attribute_id = 2 AND T1.attribute_value = (SELECT MAX(attribute_value) FROM hero_attribute WHERE attribute_id = 2)	superhero
SELECT r.race, a.alignment FROM superhero s JOIN race r ON s.race_id = r.id JOIN alignment a ON s.alignment_id = a.id WHERE s.superhero_name = 'Cameron Hicks'	superhero
SELECT CAST(COUNT(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN gender AS T3 ON T1.gender_id = T3.id JOIN publisher AS T2 ON T1.publisher_id = T2.id WHERE T3.gender = 'Female'	superhero
SELECT CAST(SUM(sh.weight_kg) AS REAL) / COUNT(sh.id) FROM superhero sh JOIN race r ON sh.race_id = r.id WHERE r.race = 'Alien'	superhero
SELECT (SUM(CASE WHEN full_name = 'Emil Blonsky' THEN weight_kg ELSE 0 END) - SUM(CASE WHEN full_name = 'Charles Chandler' THEN weight_kg ELSE 0 END)) AS CALCULATE FROM superhero	superhero
SELECT CAST(SUM(height_cm) AS REAL) / COUNT(id) FROM superhero	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Abomination'	superhero
SELECT COUNT(*) FROM superhero s JOIN gender g ON s.gender_id = g.id WHERE s.race_id = 21 AND g.id = 1	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE a.attribute_name = 'Speed' ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 WHERE T1.alignment_id = 3	superhero
SELECT a.attribute_name, ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = '3-D Man'	superhero
SELECT DISTINCT s.superhero_name FROM superhero s JOIN colour eye ON s.eye_colour_id = eye.id JOIN colour hair ON s.hair_colour_id = hair.id WHERE eye.colour = 'Blue' AND hair.colour = 'Brown'	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.superhero_name IN ('Hawkman', 'Karate Kid', 'Speedy')	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 WHERE T1.publisher_id = 1	superhero
SELECT CAST(COUNT(CASE WHEN T2.colour = 'Blue' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id	superhero
SELECT CAST(COUNT(CASE WHEN T2.gender = 'Male' THEN T1.id ELSE NULL END) AS REAL) / COUNT(CASE WHEN T2.gender = 'Female' THEN T1.id ELSE NULL END) FROM superhero T1 JOIN gender T2 ON T1.gender_id = T2.id	superhero
SELECT superhero_name FROM superhero ORDER BY height_cm DESC LIMIT 1	superhero
SELECT id FROM superpower WHERE LOWER(power_name) = 'cryokinesis'	superhero
SELECT superhero_name FROM superhero WHERE id = 294	superhero
SELECT full_name FROM superhero WHERE weight_kg = 0 OR weight_kg IS NULL	superhero
SELECT colour.colour FROM superhero JOIN colour ON superhero.eye_colour_id = colour.id WHERE superhero.full_name = 'Karen Beecher-Duncan'	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.full_name = 'Helen Parr'	superhero
SELECT r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.weight_kg = 108 AND s.height_cm = 188	superhero
SELECT p.publisher_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE s.id = 38	superhero
SELECT r.race FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN race r ON s.race_id = r.id ORDER BY ha.attribute_value DESC LIMIT 1	superhero
SELECT a.alignment, sp.power_name FROM superhero s JOIN alignment a ON s.alignment_id = a.id JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Atom IV'	superhero
SELECT superhero.superhero_name FROM superhero JOIN colour ON superhero.eye_colour_id = colour.id WHERE colour.colour = 'Blue'	superhero
SELECT AVG(T1.attribute_value) FROM hero_attribute AS T1 INNER JOIN superhero AS T2 ON T1.hero_id = T2.id WHERE T2.alignment_id = 3	superhero
SELECT DISTINCT c.colour FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN colour c ON s.skin_colour_id = c.id WHERE ha.attribute_value = 100	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN alignment AS T2 ON T1.alignment_id = T2.id INNER JOIN gender AS T3 ON T1.gender_id = T3.id WHERE T2.id = 1 AND T3.id = 2	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE ha.attribute_value BETWEEN 75 AND 80	superhero
SELECT r.race FROM superhero s JOIN colour c ON s.hair_colour_id = c.id JOIN gender g ON s.gender_id = g.id JOIN race r ON s.race_id = r.id WHERE LOWER(c.colour) = 'blue' AND LOWER(g.gender) = 'male'	superhero
SELECT CAST(COUNT(CASE WHEN g.gender = 'Female' THEN s.id ELSE NULL END) AS REAL) * 100 / COUNT(s.id) FROM superhero s JOIN alignment a ON s.alignment_id = a.id JOIN gender g ON s.gender_id = g.id WHERE a.id = 2	superhero
SELECT SUM(CASE WHEN T2.id = 7 THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.id = 1 THEN 1 ELSE 0 END) AS "SUM(CASE WHEN T2.id = 7 THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.id = 1 THEN 1 ELSE 0 END)" FROM superhero AS T1 JOIN colour AS T2 ON T1.eye_colour_id = T2.id WHERE T1.weight_kg = 0 OR T1.weight_kg IS NULL	superhero
SELECT ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = 'Hulk' AND a.attribute_name = 'Strength'	superhero
SELECT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.superhero_name = 'Ajax'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 JOIN colour AS T2 ON T1.skin_colour_id = T2.id JOIN alignment AS T3 ON T1.alignment_id = T3.id WHERE T2.colour = 'Green' AND T3.alignment = 'Bad'	superhero
SELECT COUNT(T1.id) FROM superhero AS T1 INNER JOIN gender AS T2 ON T1.gender_id = T2.id INNER JOIN publisher AS T3 ON T1.publisher_id = T3.id WHERE T2.gender = 'Female' AND T3.publisher_name = 'Marvel Comics'	superhero
SELECT s.superhero_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Wind Control' ORDER BY s.superhero_name	superhero
SELECT g.gender FROM superpower sp JOIN hero_power hp ON sp.id = hp.power_id JOIN superhero s ON hp.hero_id = s.id JOIN gender g ON s.gender_id = g.id WHERE sp.power_name = 'Phoenix Force'	superhero
SELECT s.superhero_name FROM superhero s JOIN publisher p ON s.publisher_id = p.id WHERE p.publisher_name = 'DC Comics' ORDER BY s.weight_kg DESC LIMIT 1	superhero
SELECT AVG(s.height_cm) FROM superhero s JOIN race r ON s.race_id = r.id JOIN publisher p ON s.publisher_id = p.id WHERE r.race != 'Human' AND p.publisher_name = 'Dark Horse Comics'	superhero
SELECT COUNT(T3.superhero_name) FROM attribute AS T1 INNER JOIN hero_attribute AS T2 ON T1.id = T2.attribute_id INNER JOIN superhero AS T3 ON T2.hero_id = T3.id WHERE T1.attribute_name = 'Speed' AND T2.attribute_value = 100	superhero
SELECT SUM(CASE WHEN T2.publisher_name = 'DC Comics' THEN 1 ELSE 0 END) - SUM(CASE WHEN T2.publisher_name = 'Marvel Comics' THEN 1 ELSE 0 END) FROM superhero AS T1 JOIN publisher AS T2 ON T1.publisher_id = T2.id	superhero
SELECT a.attribute_name FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id JOIN attribute a ON ha.attribute_id = a.id WHERE s.superhero_name = 'Black Panther' ORDER BY ha.attribute_value ASC LIMIT 1	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.superhero_name = 'Abomination'	superhero
SELECT superhero_name FROM superhero ORDER BY height_cm DESC LIMIT 1	superhero
SELECT superhero_name FROM superhero WHERE full_name = 'Charles Chandler'	superhero
SELECT CAST(COUNT(CASE WHEN T3.gender = 'Female' THEN 1 ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 JOIN publisher AS T2 ON T1.publisher_id = T2.id JOIN gender AS T3 ON T1.gender_id = T3.id WHERE T2.publisher_name = 'George Lucas'	superhero
SELECT CAST(COUNT(CASE WHEN T3.alignment = 'Good' THEN T1.id ELSE NULL END) AS REAL) * 100 / COUNT(T1.id) FROM superhero AS T1 INNER JOIN publisher AS T2 ON T1.publisher_id = T2.id INNER JOIN alignment AS T3 ON T1.alignment_id = T3.id WHERE T2.publisher_name = 'Marvel Comics'	superhero
SELECT COUNT(id) FROM superhero WHERE full_name LIKE 'John%'	superhero
SELECT hero_id FROM hero_attribute ORDER BY attribute_value ASC LIMIT 1	superhero
SELECT full_name FROM superhero WHERE superhero_name = 'Alien'	superhero
SELECT s.full_name FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE c.colour = 'Brown' AND s.weight_kg < 100	superhero
SELECT ha.attribute_value FROM superhero s JOIN hero_attribute ha ON s.id = ha.hero_id WHERE s.superhero_name = 'Aquababy'	superhero
SELECT s.weight_kg, r.race FROM superhero s JOIN race r ON s.race_id = r.id WHERE s.id = 40	superhero
SELECT AVG(T1.height_cm) FROM superhero AS T1 INNER JOIN alignment AS T2 ON T1.alignment_id = T2.id WHERE T2.alignment = 'Neutral'	superhero
SELECT hp.hero_id FROM hero_power hp JOIN superpower sp ON hp.power_id = sp.id WHERE sp.power_name = 'Intelligence'	superhero
SELECT c.colour FROM superhero s JOIN colour c ON s.eye_colour_id = c.id WHERE s.superhero_name = 'Blackwulf'	superhero
SELECT DISTINCT sp.power_name FROM superhero s JOIN hero_power hp ON s.id = hp.hero_id JOIN superpower sp ON hp.power_id = sp.id WHERE s.height_cm > (SELECT AVG(height_cm) * 0.8 FROM superhero)	superhero
SELECT d.driverRef FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 20 ORDER BY q.q1 DESC LIMIT 5	formula_1
SELECT d.surname FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 19 AND q.q2 IS NOT NULL AND q.q2 != '' ORDER BY CAST(q.q2 AS REAL) LIMIT 1	formula_1
SELECT r.year FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.location = 'Shanghai'	formula_1
SELECT r.url FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Circuit de Barcelona-Catalunya'	formula_1
SELECT DISTINCT r.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Germany'	formula_1
SELECT cs.position FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE c.name = 'Renault'	formula_1
SELECT COUNT(T3.raceId) FROM races AS T3 JOIN circuits AS T2 ON T3.circuitId = T2.circuitId WHERE T3.year = 2010 AND T2.country NOT IN ('Austria', 'Azerbaijan', 'Belgium', 'France', 'Germany', 'Hungary', 'Italy', 'Monaco', 'Netherlands', 'Portugal', 'Russia', 'Spain', 'Sweden', 'Switzerland', 'Turkey', 'UK', 'Bahrain', 'China', 'India', 'Japan', 'Korea', 'Malaysia', 'Singapore', 'UAE')	formula_1
SELECT DISTINCT r.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Spain'	formula_1
SELECT DISTINCT c.lat, c.lng FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE r.name = 'Australian Grand Prix'	formula_1
SELECT url FROM races WHERE circuitId = 2	formula_1
SELECT races.time FROM races JOIN circuits ON races.circuitId = circuits.circuitId WHERE circuits.name = 'Sepang International Circuit'	formula_1
SELECT DISTINCT c.lat, c.lng FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.name = 'Abu Dhabi Grand Prix'	formula_1
SELECT c.nationality FROM constructorResults cr JOIN constructors c ON cr.constructorId = c.constructorId WHERE cr.raceId = 24 AND cr.points = 1	formula_1
SELECT q1 FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE d.forename = 'Bruno' AND d.surname = 'Senna' AND q.raceId = 354	formula_1
SELECT d.nationality FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 355 AND q.q2 = '1:40.000'	formula_1
SELECT number FROM qualifying WHERE raceId = 903 AND q3 LIKE '1:54%'	formula_1
SELECT COUNT(T3.driverId) FROM races AS T1 JOIN results AS T3 ON T1.raceId = T3.raceId WHERE T1.year = 2007 AND T1.name = 'Bahrain Grand Prix' AND T3.time IS NULL	formula_1
SELECT s.url FROM races r JOIN seasons s ON r.year = s.year WHERE r.raceId = 901	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '2015-11-29' AND T2.time IS NOT NULL	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 592 AND r.time IS NOT NULL ORDER BY d.dob ASC LIMIT 1	formula_1
SELECT DISTINCT d.forename, d.surname, d.url FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId WHERE lt.raceId = 161 AND lt.time LIKE '1:27%'	formula_1
SELECT d.nationality FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 933 AND r.fastestLapSpeed IS NOT NULL ORDER BY CAST(r.fastestLapSpeed AS REAL) DESC LIMIT 1	formula_1
SELECT DISTINCT circuits.lat, circuits.lng FROM races JOIN circuits ON races.circuitId = circuits.circuitId WHERE races.name = 'Malaysian Grand Prix'	formula_1
SELECT c.url FROM constructorResults cr JOIN constructors c ON cr.constructorId = c.constructorId WHERE cr.raceId = 9 ORDER BY cr.points DESC LIMIT 1	formula_1
SELECT q1 FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 345 AND d.forename = 'Lucas' AND d.surname = 'di Grassi'	formula_1
SELECT d.nationality FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 347 AND q.q2 = '1:15.000'	formula_1
SELECT d.code FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 45 AND q.q3 LIKE '1:33%'	formula_1
SELECT time FROM results WHERE raceId = 743 AND driverId = 360	formula_1
SELECT d.forename, d.surname FROM results r JOIN races ra ON r.raceId = ra.raceId JOIN drivers d ON r.driverId = d.driverId WHERE ra.year = 2006 AND ra.name = 'San Marino Grand Prix' AND r.position = 2	formula_1
SELECT s.url FROM races r JOIN seasons s ON r.year = s.year WHERE r.raceId = 901	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '2015-11-29' AND T2.time IS NULL	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 872 AND r.time IS NOT NULL ORDER BY d.dob DESC LIMIT 1	formula_1
SELECT d.forename, d.surname FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId WHERE lt.raceId = 348 ORDER BY CAST(lt.time AS INTEGER) ASC LIMIT 1	formula_1
SELECT d."nationality" FROM results r JOIN drivers d ON r."driverId" = d."driverId" WHERE r."fastestLapSpeed" IS NOT NULL ORDER BY CAST(r."fastestLapSpeed" AS REAL) DESC LIMIT 1	formula_1
SELECT (SUM(IIF(T2.raceId = 853, CAST(T2.fastestLapSpeed AS REAL), 0)) - SUM(IIF(T2.raceId = 854, CAST(T2.fastestLapSpeed AS REAL), 0))) * 100 / SUM(IIF(T2.raceId = 853, CAST(T2.fastestLapSpeed AS REAL), 0)) FROM drivers T1 JOIN results T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Paul' AND T1.surname = 'di Resta' AND T2.raceId IN (853, 854) AND T2.fastestLapSpeed IS NOT NULL	formula_1
SELECT CAST(COUNT(CASE WHEN T2.time IS NOT NULL THEN T2.driverId END) AS REAL) * 100 / COUNT(T2.driverId) FROM races AS T1 JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.date = '1983-07-16'	formula_1
SELECT MIN(year) AS year FROM races WHERE name = 'Singapore Grand Prix'	formula_1
SELECT name FROM races WHERE year = 2005 ORDER BY name DESC	formula_1
SELECT name FROM races WHERE STRFTIME('%Y-%m', date) = (SELECT STRFTIME('%Y-%m', MIN(date)) FROM races)	formula_1
SELECT name, date FROM races WHERE year = 1999 ORDER BY round DESC LIMIT 1	formula_1
SELECT year FROM races GROUP BY year ORDER BY COUNT(*) DESC LIMIT 1	formula_1
SELECT name FROM races WHERE year = 2017 EXCEPT SELECT name FROM races WHERE year = 2000	formula_1
SELECT c.country, c.location FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.name = 'European Grand Prix' ORDER BY r.year LIMIT 1	formula_1
SELECT r.date FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE c.name = 'Brands Hatch' AND r.name = 'British Grand Prix' ORDER BY r.year DESC LIMIT 1	formula_1
SELECT COUNT(T2.circuitId) FROM races AS T1 JOIN circuits AS T2 ON T1.circuitId = T2.circuitId WHERE T1.name = 'British Grand Prix' AND T2.name = 'Silverstone Circuit'	formula_1
SELECT d.forename, d.surname FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.year = 2010 AND r.name = 'Singapore Grand Prix' ORDER BY res.position	formula_1
SELECT d.forename, d.surname, SUM(ds.points) AS points FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId GROUP BY d.driverId, d.forename, d.surname ORDER BY points DESC LIMIT 1	formula_1
SELECT d.forename, d.surname, r.points FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.raceId = 970 ORDER BY r.points DESC LIMIT 3	formula_1
SELECT lt.milliseconds, d.forename, d.surname, r.name FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId JOIN races r ON lt.raceId = r.raceId ORDER BY lt.milliseconds ASC LIMIT 1	formula_1
SELECT AVG(T2.milliseconds) FROM drivers AS T1 INNER JOIN lapTimes AS T2 ON T1.driverId = T2.driverId INNER JOIN races AS T3 ON T2.raceId = T3.raceId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton' AND T3.name = 'Malaysian Grand Prix' AND T3.year = 2009	formula_1
SELECT CAST(COUNT(CASE WHEN T2.position <> 1 THEN T2.position END) AS REAL) * 100 / COUNT(T2.driverStandingsId) FROM drivers T1 JOIN driverStandings T2 ON T1.driverId = T2.driverId JOIN races T3 ON T2.raceId = T3.raceId WHERE T1.surname = 'Hamilton' AND T3.year >= 2010	formula_1
SELECT d.forename, d.surname, d.nationality, MAX(ds.points) AS "MAX(T2.points)" FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId GROUP BY d.driverId, d.forename, d.surname, d.nationality ORDER BY SUM(ds.wins) DESC LIMIT 1	formula_1
SELECT STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', dob), forename, surname FROM drivers WHERE nationality = 'Japanese' ORDER BY dob DESC LIMIT 1	formula_1
SELECT c.name FROM circuits c JOIN races r ON c.circuitId = r.circuitId WHERE r.year BETWEEN 1990 AND 2000 GROUP BY c.circuitId, c.name HAVING COUNT(*) = 4	formula_1
SELECT circuits.name, circuits.location, races.name FROM circuits JOIN races ON circuits.circuitId = races.circuitId WHERE circuits.country = 'USA' AND races.year = 2006	formula_1
SELECT races.name, circuits.name, circuits.location FROM races JOIN circuits ON races.circuitId = circuits.circuitId WHERE strftime('%Y', races.date) = '2005' AND strftime('%m', races.date) = '09'	formula_1
SELECT r.name FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Alex' AND d.surname = 'Yoong' AND res.position < 20	formula_1
SELECT SUM(T2.wins) FROM drivers AS T1 INNER JOIN driverStandings AS T2 ON T1.driverId = T2.driverId INNER JOIN races AS T3 ON T2.raceId = T3.raceId INNER JOIN circuits AS T4 ON T3.circuitId = T4.circuitId WHERE T1.forename = 'Michael' AND T1.surname = 'Schumacher' AND T4.name = 'Sepang International Circuit'	formula_1
SELECT r.name, r.year FROM results res JOIN drivers d ON res.driverId = d.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Michael' AND d.surname = 'Schumacher' AND res.milliseconds IS NOT NULL ORDER BY res.milliseconds ASC LIMIT 1	formula_1
SELECT AVG(T2.points) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId INNER JOIN races AS T3 ON T2.raceId = T3.raceId WHERE T1.forename = 'Eddie' AND T1.surname = 'Irvine' AND T3.year = 2000	formula_1
SELECT r.name, res.points FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY r.year ASC LIMIT 1	formula_1
SELECT r.name, c.country FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2017 ORDER BY r.date	formula_1
SELECT MAX(lt.lap) as lap, r.name, r.year, c.location FROM lapTimes lt JOIN races r ON lt.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId GROUP BY r.raceId, r.name, r.year, c.location ORDER BY lap DESC LIMIT 1	formula_1
SELECT CAST(COUNT(CASE WHEN T1.country = 'Germany' THEN T2.circuitId END) AS REAL) * 100 / COUNT(T2.circuitId) FROM circuits AS T1 JOIN races AS T2 ON T1.circuitId = T2.circuitId WHERE T2.name = 'European Grand Prix'	formula_1
SELECT lat, lng FROM circuits WHERE name = 'Silverstone Circuit'	formula_1
SELECT name FROM circuits WHERE name IN ('Silverstone Circuit', 'Hockenheimring', 'Hungaroring') ORDER BY lat DESC LIMIT 1	formula_1
SELECT circuitRef FROM circuits WHERE name = 'Marina Bay Street Circuit'	formula_1
SELECT country FROM circuits WHERE alt = (SELECT MAX(alt) FROM circuits)	formula_1
SELECT COUNT(driverId) - COUNT(CASE WHEN code IS NOT NULL THEN code END) FROM drivers	formula_1
SELECT nationality FROM drivers ORDER BY dob ASC LIMIT 1	formula_1
SELECT surname FROM drivers WHERE nationality = 'Italian'	formula_1
SELECT url FROM drivers WHERE forename = 'Anthony' AND surname = 'Davidson'	formula_1
SELECT driverRef FROM drivers WHERE forename = 'Lewis' AND surname = 'Hamilton'	formula_1
SELECT c.name FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2009 AND r.name = 'Spanish Grand Prix'	formula_1
SELECT year FROM races WHERE circuitId = 9 ORDER BY year	formula_1
SELECT url FROM circuits WHERE name = 'Silverstone Circuit'	formula_1
SELECT date, time FROM races WHERE year = 2010 AND circuitId = 24	formula_1
SELECT COUNT(T2.circuitId) FROM races AS T1 INNER JOIN circuits AS T2 ON T1.circuitId = T2.circuitId WHERE T2.country = 'Italy'	formula_1
SELECT r.date FROM races r JOIN circuits c ON r.circuitId = c.circuitId WHERE c.name = 'Circuit de Barcelona-Catalunya' ORDER BY r.date	formula_1
SELECT circuits.url FROM races JOIN circuits ON races.circuitId = circuits.circuitId WHERE races.year = 2009 AND races.name = 'Spanish Grand Prix'	formula_1
SELECT MIN(CAST(r.fastestLapTime AS REAL)) AS fastestLapTime FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND r.fastestLapTime IS NOT NULL AND r.fastestLapTime != ''	formula_1
SELECT d.forename, d.surname FROM results r JOIN drivers d ON r.driverId = d.driverId WHERE r.fastestLapSpeed IS NOT NULL ORDER BY CAST(r.fastestLapSpeed AS REAL) DESC LIMIT 1	formula_1
SELECT d.forename, d.surname, d.driverRef FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.name = 'Canadian Grand Prix' AND r.year = 2007 AND res.position = 1	formula_1
SELECT DISTINCT r.name FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY r.name	formula_1
SELECT r.name FROM results res JOIN drivers d ON res.driverId = d.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND res.rank IS NOT NULL ORDER BY res.rank ASC LIMIT 1	formula_1
SELECT MAX(CAST("results"."fastestLapSpeed" AS REAL)) AS fastestLapSpeed FROM "results" JOIN "races" ON "results"."raceId" = "races"."raceId" WHERE "races"."year" = 2009 AND "races"."name" = 'Spanish Grand Prix' AND "results"."fastestLapSpeed" IS NOT NULL	formula_1
SELECT DISTINCT r.year FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY r.year	formula_1
SELECT r.positionOrder FROM results r JOIN drivers d ON r.driverId = d.driverId JOIN races ra ON r.raceId = ra.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND ra.year = 2008 AND ra.name = 'Chinese Grand Prix'	formula_1
SELECT d.forename, d.surname FROM races r JOIN results res ON r.raceId = res.raceId JOIN drivers d ON res.driverId = d.driverId WHERE r.year = 1989 AND r.name = 'Australian Grand Prix' AND res.grid = 4	formula_1
SELECT COUNT(T2.driverId) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T1.year = 2008 AND T1.name = 'Australian Grand Prix' AND T2.time IS NOT NULL	formula_1
SELECT r.fastestLapTime AS fastestLap FROM results r JOIN drivers d ON r.driverId = d.driverId JOIN races ra ON r.raceId = ra.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND ra.year = 2008 AND ra.name = 'Australian Grand Prix'	formula_1
SELECT r.time FROM results r JOIN races ra ON r.raceId = ra.raceId WHERE ra.year = 2008 AND ra.name = 'Chinese Grand Prix' AND r.position = 2	formula_1
SELECT 1	formula_1
SELECT COUNT(*) FROM drivers d JOIN results r ON d.driverId = r.driverId JOIN races ra ON r.raceId = ra.raceId WHERE d.nationality = 'British' AND ra.year = 2008 AND ra.name = 'Australian Grand Prix'	formula_1
SELECT COUNT(*) FROM results WHERE raceId = 34 AND time IS NOT NULL	formula_1
SELECT SUM(T2.points) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton'	formula_1
SELECT AVG(CAST(SUBSTR(T2.fastestLapTime, 1, INSTR(T2.fastestLapTime, ':') - 1) AS INTEGER) * 60 + CAST(SUBSTR(T2.fastestLapTime, INSTR(T2.fastestLapTime, ':') + 1) AS REAL)) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.forename = 'Lewis' AND T1.surname = 'Hamilton' AND T2.fastestLapTime IS NOT NULL	formula_1
SELECT 1	formula_1
WITH race_info AS ( SELECT raceId FROM races WHERE year = 2008 AND name LIKE '%Australian%' ), champion_time AS ( SELECT milliseconds AS time_seconds FROM results r JOIN race_info ri ON r.raceId = ri.raceId WHERE r.position = 1 AND r.time IS NOT NULL ), last_finisher AS ( SELECT milliseconds AS time_seconds FROM results r JOIN race_info ri ON r.raceId = ri.raceId WHERE r.time IS NOT NULL ORDER BY r.position DESC LIMIT 1 ), last_driver_incremental AS ( SELECT (lf.time_seconds - ct.time_seconds) AS time_seconds FROM last_finisher lf, champion_time ct ) SELECT (CAST((SELECT time_seconds FROM last_driver_incremental) AS REAL) * 100) / (SELECT time_seconds + (SELECT time_seconds FROM last_driver_incremental) FROM champion_time) AS "(CAST((SELECT time_seconds FROM last_driver_incremental) AS REAL) * 100) / (SELECT time_seconds + (SELECT time_seconds FROM last_driver_incremental) FROM champion_time)" FROM champion_time LIMIT 1	formula_1
SELECT COUNT(circuitId) FROM circuits WHERE location = 'Adelaide' AND country = 'Australia'	formula_1
SELECT lat, lng FROM circuits WHERE country = 'USA'	formula_1
SELECT COUNT(driverId) FROM drivers WHERE nationality = 'British' AND STRFTIME('%Y', dob) > '1980'	formula_1
SELECT MAX(T1.points) FROM constructorResults AS T1 JOIN constructors AS T2 ON T1.constructorId = T2.constructorId WHERE T2.nationality = 'British'	formula_1
SELECT c.name FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId ORDER BY cs.points DESC LIMIT 1	formula_1
SELECT c.name FROM constructorResults cr JOIN constructors c ON cr.constructorId = c.constructorId WHERE cr.raceId = 291 AND cr.points = 0	formula_1
SELECT COUNT(T1.raceId) FROM constructorResults AS T1 JOIN constructors AS T2 ON T1.constructorId = T2.constructorId WHERE T2.nationality = 'Japanese' AND T1.points = 0 GROUP BY T1.constructorId HAVING COUNT(T1.raceId) = 2	formula_1
SELECT DISTINCT c.name FROM constructorStandings cs JOIN constructors c ON cs.constructorId = c.constructorId WHERE cs.position = 1	formula_1
SELECT COUNT(DISTINCT T2.constructorId) FROM results AS T1 JOIN constructors AS T2 ON T1.constructorId = T2.constructorId WHERE T2.nationality = 'French' AND T1.laps > 50	formula_1
SELECT CAST(SUM(IIF(T1.time IS NOT NULL, 1, 0)) AS REAL) * 100 / COUNT(T1.raceId) FROM results AS T1 JOIN drivers AS T2 ON T1.driverId = T2.driverId JOIN races AS T3 ON T1.raceId = T3.raceId WHERE T2.nationality = 'Japanese' AND T3.year BETWEEN 2007 AND 2009	formula_1
SELECT r.year, AVG( CAST(SUBSTR(res.time, 1, INSTR(res.time, ':') - 1) AS REAL) * 3600 + CAST(SUBSTR(res.time, INSTR(res.time, ':') + 1, INSTR(SUBSTR(res.time, INSTR(res.time, ':') + 1), ':') - 1) AS REAL) * 60 + CAST(SUBSTR(SUBSTR(res.time, INSTR(res.time, ':') + 1), INSTR(SUBSTR(res.time, INSTR(res.time, ':') + 1), ':') + 1, INSTR(res.time, '.') - INSTR(res.time, ':') - INSTR(SUBSTR(res.time, INSTR(res.time, ':') + 1), ':') - 1) AS REAL) + CAST(SUBSTR(res.time, INSTR(res.time, '.') + 1) AS REAL) / 1000 ) AS AVG_time_seconds FROM races r JOIN results res ON r.raceId = res.raceId WHERE r.year < 1975 AND res.position = 1 AND res.time IS NOT NULL GROUP BY r.year ORDER BY r.year	formula_1
SELECT DISTINCT d.forename, d.surname FROM drivers d JOIN results r ON d.driverId = r.driverId WHERE strftime('%Y', d.dob) > '1975' AND r.rank = 2	formula_1
SELECT COUNT(T1.driverId) FROM drivers AS T1 INNER JOIN results AS T2 ON T1.driverId = T2.driverId WHERE T1.nationality = 'Italian' AND T2.time IS NULL	formula_1
SELECT d.forename, d.surname, lt.time AS fastestLapTime FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId ORDER BY lt.milliseconds ASC LIMIT 1	formula_1
SELECT r.fastestLap FROM races ra JOIN driverStandings ds ON ra.raceId = ds.raceId JOIN results r ON ds.driverId = r.driverId AND ra.raceId = r.raceId WHERE ra.year = 2009 AND ds.position = 1 AND r.fastestLap IS NOT NULL LIMIT 1	formula_1
SELECT AVG(CAST(T1.fastestLapSpeed AS REAL)) AS "AVG(T1.fastestLapSpeed)" FROM results T1 JOIN races T2 ON T1.raceId = T2.raceId WHERE T2.year = 2009 AND T2.name = 'Spanish Grand Prix'	formula_1
SELECT r.name, r.year FROM results res JOIN races r ON res.raceId = r.raceId WHERE res.milliseconds IS NOT NULL ORDER BY res.milliseconds ASC LIMIT 1	formula_1
SELECT CAST(SUM(IIF(STRFTIME('%Y', T3.dob) < '1985' AND T1.laps > 50, 1, 0)) AS REAL) * 100 / COUNT(*) FROM results AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId JOIN drivers AS T3 ON T1.driverId = T3.driverId WHERE T2.year BETWEEN 2000 AND 2005	formula_1
SELECT COUNT(DISTINCT T1.driverId) FROM drivers AS T1 INNER JOIN lapTimes AS T2 ON T1.driverId = T2.driverId WHERE T1.nationality = 'French' AND T2.milliseconds < 120000	formula_1
SELECT code FROM drivers WHERE nationality = 'American'	formula_1
SELECT raceId FROM races WHERE year = 2009	formula_1
SELECT COUNT(driverId) FROM results WHERE raceId = 18	formula_1
SELECT COUNT(*) FROM (SELECT nationality FROM drivers ORDER BY dob DESC LIMIT 3) WHERE nationality = 'Dutch'	formula_1
SELECT driverRef FROM drivers WHERE forename = 'Robert' AND surname = 'Kubica'	formula_1
SELECT COUNT(driverId) FROM drivers WHERE nationality = 'British' AND STRFTIME('%Y', dob) = '1980'	formula_1
SELECT d.driverId FROM drivers d JOIN lapTimes lt ON d.driverId = lt.driverId WHERE d.nationality = 'German' AND strftime('%Y', d.dob) BETWEEN '1980' AND '1990' GROUP BY d.driverId ORDER BY MIN(CAST(lt.time AS INTEGER)) LIMIT 3	formula_1
SELECT driverRef FROM drivers WHERE nationality = 'German' ORDER BY dob ASC LIMIT 1	formula_1
SELECT d.driverId, d.code FROM drivers d JOIN results r ON d.driverId = r.driverId WHERE strftime('%Y', d.dob) = '1971' AND r.fastestLapTime IS NOT NULL ORDER BY CAST(r.fastestLapTime AS REAL) ASC LIMIT 1	formula_1
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
SELECT MIN(milliseconds) AS milliseconds FROM lapTimes WHERE lap = 1	formula_1
SELECT AVG( CAST(SUBSTR(T1.fastestLapTime, 1, INSTR(T1.fastestLapTime, ':') - 1) AS REAL) * 60 + CAST(SUBSTR(T1.fastestLapTime, INSTR(T1.fastestLapTime, ':') + 1) AS REAL) ) AS "AVG(T1.fastestLapTime)" FROM results AS T1 WHERE T1.raceId = 62 AND T1.rank < 11	formula_1
SELECT d.forename, d.surname FROM drivers d JOIN pitStops p ON d.driverId = p.driverId WHERE d.nationality = 'German' AND STRFTIME('%Y', d.dob) BETWEEN '1980' AND '1985' GROUP BY d.driverId, d.forename, d.surname ORDER BY AVG(CAST(p.duration AS REAL)) ASC LIMIT 3	formula_1
SELECT r.time FROM races ra JOIN results r ON ra.raceId = r.raceId WHERE ra.year = 2008 AND ra.name = 'Canadian Grand Prix' AND r.position = 1	formula_1
SELECT c.constructorRef, c.url FROM results r JOIN constructors c ON r.constructorId = c.constructorId WHERE r.raceId = 14 AND r.position = 1	formula_1
SELECT forename, surname, dob FROM drivers WHERE nationality = 'Austrian' AND STRFTIME('%Y', dob) BETWEEN '1981' AND '1991'	formula_1
SELECT forename, surname, url, dob FROM drivers WHERE nationality = 'German' AND STRFTIME('%Y', dob) BETWEEN '1971' AND '1985' ORDER BY dob DESC	formula_1
SELECT country, lat, lng FROM circuits WHERE name = 'Hungaroring'	formula_1
SELECT SUM(T1.points), T3.name, T3.nationality FROM constructorResults AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId JOIN constructors AS T3 ON T1.constructorId = T3.constructorId WHERE T2.name = 'Monaco Grand Prix' AND T2.year BETWEEN 1980 AND 2010 GROUP BY T3.constructorId, T3.name, T3.nationality ORDER BY SUM(T1.points) DESC LIMIT 1	formula_1
SELECT AVG(T2.points) FROM races AS T1 INNER JOIN results AS T2 ON T1.raceId = T2.raceId WHERE T2.driverId = 1 AND T1.name = 'Turkish Grand Prix'	formula_1
SELECT CAST(SUM(CASE WHEN year BETWEEN 2000 AND 2010 THEN 1 ELSE 0 END) AS REAL) / 10 FROM races	formula_1
SELECT nationality FROM drivers GROUP BY nationality ORDER BY COUNT(*) DESC LIMIT 1	formula_1
SELECT SUM(CASE WHEN points = 91 THEN wins ELSE 0 END) FROM driverStandings	formula_1
SELECT r.name FROM results res JOIN races r ON res.raceId = r.raceId WHERE res.fastestLapTime IS NOT NULL ORDER BY CAST(res.fastestLapTime AS INTEGER) LIMIT 1	formula_1
SELECT circuits.location || ', ' || circuits.country AS location FROM races JOIN circuits ON races.circuitId = circuits.circuitId ORDER BY races.date DESC LIMIT 1	formula_1
SELECT d.forename, d.surname FROM qualifying q JOIN drivers d ON q.driverId = d.driverId WHERE q.raceId = 32 AND q.q3 IS NOT NULL AND q.q3 != '' ORDER BY CAST(q.q3 AS REAL) ASC LIMIT 1	formula_1
SELECT d.forename, d.surname, d.nationality, r.name FROM drivers d JOIN results res ON d.driverId = res.driverId JOIN races r ON res.raceId = r.raceId WHERE d.dob = (SELECT MAX(dob) FROM drivers WHERE dob IS NOT NULL) ORDER BY r.date LIMIT 1	formula_1
SELECT COUNT(T1.driverId) FROM results AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId WHERE T2.name = 'Canadian Grand Prix' AND T1.statusId = 3 GROUP BY T1.driverId ORDER BY COUNT(T1.driverId) DESC LIMIT 1	formula_1
SELECT SUM(ds.wins) AS "SUM(T1.wins)", d.forename, d.surname FROM drivers d JOIN driverStandings ds ON d.driverId = ds.driverId WHERE d.dob = (SELECT MIN(dob) FROM drivers WHERE dob IS NOT NULL) GROUP BY d.forename, d.surname	formula_1
SELECT MAX(CAST("duration" AS REAL)) AS duration FROM "pitStops"	formula_1
SELECT "fastestLapTime" AS time FROM results WHERE "fastestLapTime" IS NOT NULL ORDER BY CAST(SUBSTR("fastestLapTime", 1, INSTR("fastestLapTime", ':') - 1) AS INTEGER) * 60000 + CAST(SUBSTR("fastestLapTime", INSTR("fastestLapTime", ':') + 1, INSTR(SUBSTR("fastestLapTime", INSTR("fastestLapTime", ':') + 1), '.') - 1) AS INTEGER) * 1000 + CAST(SUBSTR("fastestLapTime", INSTR("fastestLapTime", '.') + 1) AS INTEGER) ASC LIMIT 1	formula_1
SELECT MAX(CAST("pitStops"."duration" AS REAL)) AS duration FROM "pitStops" JOIN "drivers" ON "pitStops"."driverId" = "drivers"."driverId" WHERE "drivers"."forename" = 'Lewis' AND "drivers"."surname" = 'Hamilton'	formula_1
SELECT ps.lap FROM pitStops ps JOIN drivers d ON ps.driverId = d.driverId JOIN races r ON ps.raceId = r.raceId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' AND r.year = 2011 AND r.name = 'Australian Grand Prix'	formula_1
SELECT p.duration FROM pitStops p JOIN races r ON p.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId WHERE r.year = 2011 AND c.country = 'Australia'	formula_1
SELECT time FROM lapTimes WHERE driverId = 1 ORDER BY milliseconds ASC LIMIT 1	formula_1
SELECT d.forename, d.surname, d.driverId FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId ORDER BY lt.milliseconds ASC LIMIT 1	formula_1
SELECT lt.position FROM lapTimes lt JOIN drivers d ON lt.driverId = d.driverId WHERE d.forename = 'Lewis' AND d.surname = 'Hamilton' ORDER BY CAST(lt.time AS REAL) ASC LIMIT 1	formula_1
SELECT MIN(lt.milliseconds) AS lap_record FROM lapTimes lt JOIN races r ON lt.raceId = r.raceId JOIN circuits c ON r.circuitId = c.circuitId WHERE c.country = 'Austria'	formula_1
SELECT MIN(lt."milliseconds") AS lap_record FROM "circuits" c JOIN "races" r ON c."circuitId" = r."circuitId" JOIN "lapTimes" lt ON r."raceId" = lt."raceId" WHERE c."country" = 'Italy'	formula_1
SELECT r.name FROM circuits c JOIN races r ON c.circuitId = r.circuitId JOIN lapTimes lt ON r.raceId = lt.raceId WHERE c.circuitId IN (23, 57, 70) ORDER BY CAST(lt.time AS INTEGER) ASC LIMIT 1	formula_1
SELECT ps.duration FROM races r JOIN lapTimes lt ON r.raceId = lt.raceId JOIN pitStops ps ON r.raceId = ps.raceId AND lt.driverId = ps.driverId WHERE r.name LIKE '%Austrian Grand Prix%' ORDER BY CAST(lt.time AS INTEGER) ASC LIMIT 1	formula_1
SELECT c.lat, c.lng FROM circuits c JOIN races r ON c.circuitId = r.circuitId JOIN results res ON r.raceId = res.raceId WHERE res.fastestLapTime = '1:29.488'	formula_1
SELECT AVG(pitStops.milliseconds) FROM pitStops JOIN drivers ON pitStops.driverId = drivers.driverId WHERE drivers.forename = 'Lewis' AND drivers.surname = 'Hamilton'	formula_1
SELECT CAST(SUM(T1.milliseconds) AS REAL) / COUNT(T1.lap) FROM lapTimes AS T1 JOIN races AS T2 ON T1.raceId = T2.raceId JOIN circuits AS T3 ON T2.circuitId = T3.circuitId WHERE T3.country = 'Italy'	formula_1
SELECT player_api_id FROM Player_Attributes ORDER BY overall_rating DESC LIMIT 1	european_football_2
SELECT player_name FROM Player ORDER BY height DESC LIMIT 1	european_football_2
SELECT preferred_foot FROM Player_Attributes WHERE potential = (SELECT MIN(potential) FROM Player_Attributes) AND preferred_foot IS NOT NULL ORDER BY potential ASC LIMIT 1	european_football_2
SELECT COUNT(id) FROM Player_Attributes WHERE overall_rating >= 60 AND overall_rating < 65 AND defensive_work_rate = 'low'	european_football_2
SELECT p.id FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id GROUP BY p.id ORDER BY MAX(pa.crossing) DESC LIMIT 5	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2015/2016' GROUP BY l.id, l.name ORDER BY SUM(m.home_team_goal + m.away_team_goal) DESC LIMIT 1	european_football_2
SELECT t.team_long_name FROM Match m JOIN Team t ON m.home_team_api_id = t.team_api_id WHERE m.season = '2015/2016' AND m.home_team_goal < m.away_team_goal GROUP BY t.team_long_name ORDER BY COUNT(*) ASC LIMIT 1	european_football_2
SELECT Player.player_name FROM Player INNER JOIN Player_Attributes ON Player.player_api_id = Player_Attributes.player_api_id GROUP BY Player.player_name ORDER BY MAX(Player_Attributes.penalties) DESC LIMIT 10	european_football_2
SELECT t.team_long_name FROM Match m JOIN League l ON m.league_id = l.id JOIN Team t ON m.away_team_api_id = t.team_api_id WHERE l.name = 'Scotland Premier League' AND m.season = '2009/2010' AND m.away_team_goal > m.home_team_goal GROUP BY t.team_api_id, t.team_long_name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT buildUpPlaySpeed FROM Team_Attributes ORDER BY buildUpPlaySpeed DESC LIMIT 4	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2015/2016' AND m.home_team_goal = m.away_team_goal GROUP BY l.id, l.name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT CAST(strftime('%Y', 'now') AS INTEGER) - CAST(strftime('%Y', p.birthday) AS INTEGER) AS age FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.sprint_speed >= 97 AND CAST(strftime('%Y', pa.date) AS INTEGER) >= 2013 AND CAST(strftime('%Y', pa.date) AS INTEGER) <= 2015	european_football_2
SELECT League.name, COUNT(Match.league_id) AS max_count FROM Match JOIN League ON Match.league_id = League.id GROUP BY League.name ORDER BY max_count DESC LIMIT 1	european_football_2
SELECT SUM(height) / COUNT(id) FROM Player WHERE birthday >= '1990-01-01 00:00:00' AND birthday < '1996-01-01 00:00:00'	european_football_2
SELECT DISTINCT player_api_id FROM Player_Attributes WHERE substr(date,1,4) = '2010' AND overall_rating = (SELECT MAX(overall_rating) FROM Player_Attributes WHERE substr(date,1,4) = '2010' AND overall_rating > (SELECT AVG(overall_rating) FROM Player_Attributes WHERE substr(date,1,4) = '2010'))	european_football_2
SELECT DISTINCT team_fifa_api_id FROM Team_Attributes WHERE buildUpPlaySpeed > 50 AND buildUpPlaySpeed < 60	european_football_2
SELECT DISTINCT t.team_long_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE strftime('%Y', ta.date) = '2012' AND ta.buildUpPlayPassing IS NOT NULL AND ta.buildUpPlayPassing > ( SELECT AVG(buildUpPlayPassing) FROM Team_Attributes WHERE strftime('%Y', date) = '2012' AND buildUpPlayPassing IS NOT NULL )	european_football_2
SELECT CAST(SUM(CASE WHEN pa.preferred_foot = 'left' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(pa.player_fifa_api_id) AS percent FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id WHERE CAST(SUBSTR(p.birthday, 1, 4) AS INTEGER) BETWEEN 1987 AND 1992	european_football_2
SELECT l.name, SUM(m.home_team_goal) + SUM(m.away_team_goal) FROM League l JOIN Match m ON l.id = m.league_id GROUP BY l.name ORDER BY SUM(m.home_team_goal) + SUM(m.away_team_goal) ASC LIMIT 5	european_football_2
SELECT CAST(SUM(t2.long_shots) AS REAL) / COUNT(t2.`date`) FROM Player AS t1 LEFT JOIN Player_Attributes AS t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE t1.player_name = 'Ahmed Samir Farag'	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.height > 180 GROUP BY p.player_api_id, p.player_name ORDER BY AVG(pa.heading_accuracy) DESC LIMIT 10	european_football_2
SELECT t.team_long_name FROM Team_Attributes ta JOIN Team t ON ta.team_api_id = t.team_api_id WHERE ta.buildUpPlayDribblingClass = 'Normal' AND ta.date >= '2014-01-01 00:00:00' AND ta.date <= '2014-12-31 23:59:59' AND ta.chanceCreationPassing < ( SELECT AVG(ta2.chanceCreationPassing) FROM Team_Attributes ta2 WHERE ta2.buildUpPlayDribblingClass = 'Normal' AND ta2.date >= '2014-01-01 00:00:00' AND ta2.date <= '2014-12-31 23:59:59' ) ORDER BY ta.chanceCreationPassing DESC	european_football_2
SELECT League.name FROM Match JOIN League ON Match.league_id = League.id WHERE Match.season = '2009/2010' GROUP BY League.name HAVING AVG(Match.home_team_goal) > AVG(Match.away_team_goal)	european_football_2
SELECT team_short_name FROM Team WHERE team_long_name = 'Queens Park Rangers'	european_football_2
SELECT player_name FROM Player WHERE substr(birthday, 1, 4) = '1970' AND substr(birthday, 6, 2) = '10'	european_football_2
SELECT DISTINCT pa.attacking_work_rate FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Franco Zennaro'	european_football_2
SELECT DISTINCT ta.buildUpPlayPositioningClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'ADO Den Haag'	european_football_2
SELECT pa.heading_accuracy FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Francois Affolter' AND pa.date = '2014-09-18 00:00:00'	european_football_2
SELECT pa.overall_rating FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Gabriel Tamas' AND strftime('%Y', pa.date) = '2011'	european_football_2
SELECT COUNT(t2.id) FROM Match AS t2 JOIN League AS t1 ON t2.league_id = t1.id WHERE t1.name = 'Scotland Premier League' AND t2.season = '2015/2016'	european_football_2
SELECT pa.preferred_foot FROM Player p JOIN Player_Attributes pa ON p.player_fifa_api_id = pa.player_fifa_api_id WHERE CAST(p.birthday AS INTEGER) = (SELECT MAX(CAST(birthday AS INTEGER)) FROM Player) LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.potential = (SELECT MAX(potential) FROM Player_Attributes)	european_football_2
SELECT COUNT(DISTINCT t1.id) FROM Player AS t1 JOIN Player_Attributes AS t2 ON t1.player_api_id = t2.player_api_id WHERE t1.weight < 130 AND t2.preferred_foot = 'left'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.chanceCreationPassingClass = 'Risky'	european_football_2
SELECT DISTINCT pa.defensive_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'David Wilson'	european_football_2
SELECT p.birthday FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT League.name FROM League JOIN Country ON League.country_id = Country.id WHERE Country.name = 'Netherlands'	european_football_2
SELECT CAST(SUM(m.home_team_goal) AS REAL) / COUNT(m.id) FROM Match m JOIN Country c ON m.country_id = c.id WHERE c.name = 'Poland' AND m.season = '2010/2011'	european_football_2
WITH height_extremes AS ( SELECT MAX(height) as max_height, MIN(height) as min_height FROM Player ), max_height_avg AS ( SELECT AVG(pa.finishing) as avg_finishing, 'Max' as height_group FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.height = (SELECT max_height FROM height_extremes) ), min_height_avg AS ( SELECT AVG(pa.finishing) as avg_finishing, 'Min' as height_group FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.height = (SELECT min_height FROM height_extremes) ) SELECT CASE WHEN (SELECT avg_finishing FROM max_height_avg) > (SELECT avg_finishing FROM min_height_avg) THEN 'Max' ELSE 'Min' END as A	european_football_2
SELECT DISTINCT player_name FROM Player WHERE height > 180	european_football_2
SELECT COUNT(id) FROM Player WHERE strftime('%Y', birthday) = '1990'	european_football_2
SELECT COUNT(id) FROM Player WHERE player_name LIKE 'Adam %' AND weight > 170	european_football_2
SELECT DISTINCT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.overall_rating > 80 AND strftime('%Y', pa.date) BETWEEN '2008' AND '2010'	european_football_2
SELECT pa.potential FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Aaron Doran'	european_football_2
SELECT DISTINCT p.id, p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.preferred_foot = 'left'	european_football_2
SELECT DISTINCT T.team_long_name FROM Team T JOIN Team_Attributes TA ON T.team_api_id = TA.team_api_id WHERE TA.buildUpPlaySpeedClass = 'Fast'	european_football_2
SELECT DISTINCT ta.buildUpPlayPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_short_name = 'CLB'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.buildUpPlayPassing > 70	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.height > 170 AND strftime('%Y', t2.date) >= '2010' AND strftime('%Y', t2.date) <= '2015'	european_football_2
SELECT player_name FROM Player ORDER BY height ASC LIMIT 1	european_football_2
SELECT c.name FROM League l JOIN Country c ON l.country_id = c.id WHERE l.name = 'Italy Serie A'	european_football_2
SELECT DISTINCT T.team_short_name FROM Team T JOIN Team_Attributes TA ON T.team_api_id = TA.team_api_id WHERE TA.buildUpPlaySpeed = 31 AND TA.buildUpPlayDribbling = 53 AND TA.buildUpPlayPassing = 32	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Aaron Doran'	european_football_2
SELECT COUNT(t2.id) FROM Match AS t2 JOIN League AS t3 ON t2.league_id = t3.id WHERE t3.name = 'Germany 1. Bundesliga' AND strftime('%Y-%m', t2.date) BETWEEN '2008-08' AND '2008-10'	european_football_2
SELECT T.team_short_name FROM Match M JOIN Team T ON M.home_team_api_id = T.team_api_id WHERE M.home_team_goal = 10	european_football_2
SELECT DISTINCT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.potential = 61 AND pa.balance = ( SELECT MAX(balance) FROM Player_Attributes WHERE potential = 61 )	european_football_2
SELECT CAST(SUM(CASE WHEN t1.player_name = 'Abdou Diallo' THEN t2.ball_control ELSE 0 END) AS REAL) / COUNT(CASE WHEN t1.player_name = 'Abdou Diallo' THEN t2.id ELSE NULL END) - CAST(SUM(CASE WHEN t1.player_name = 'Aaron Appindangoye' THEN t2.ball_control ELSE 0 END) AS REAL) / COUNT(CASE WHEN t1.player_name = 'Aaron Appindangoye' THEN t2.id ELSE NULL END) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id	european_football_2
SELECT team_long_name FROM Team WHERE team_short_name = 'GEN'	european_football_2
SELECT player_name FROM Player WHERE player_name IN ('Aaron Lennon', 'Abdelaziz Barrada') ORDER BY CAST(birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT player_name FROM Player ORDER BY height DESC LIMIT 1	european_football_2
SELECT COUNT(player_api_id) FROM Player_Attributes WHERE preferred_foot = 'left' AND attacking_work_rate = 'low'	european_football_2
SELECT Country.name FROM League JOIN Country ON League.country_id = Country.id WHERE League.name = 'Belgium Jupiler League'	european_football_2
SELECT League.name FROM League JOIN Country ON League.country_id = Country.id WHERE Country.name = 'Germany'	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT COUNT(DISTINCT t1.player_name) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE strftime('%Y', t1.birthday) < '1986' AND t2.defensive_work_rate = 'high'	european_football_2
SELECT p.player_name, MAX(pa.crossing) AS crossing FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name IN ('Alexis', 'Ariel Borysiuk', 'Arouna Kone') GROUP BY p.player_name ORDER BY crossing DESC	european_football_2
SELECT pa.heading_accuracy FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Ariel Borysiuk'	european_football_2
SELECT COUNT(DISTINCT t1.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.height > 180 AND t2.volleys > 70	european_football_2
SELECT DISTINCT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.volleys > 70 AND pa.dribbling > 70	european_football_2
SELECT COUNT(t2.id) FROM Match AS t2 JOIN Country AS t1 ON t2.country_id = t1.id WHERE t1.name = 'Belgium' AND t2.season = '2008/2009'	european_football_2
SELECT pa.long_passing FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id ORDER BY CAST(p.birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT COUNT(t2.id) FROM Match AS t2 JOIN League AS t1 ON t2.league_id = t1.id WHERE t1.name = 'Belgium Jupiler League' AND SUBSTR(t2.date, 1, 7) = '2009-04'	european_football_2
SELECT l.name FROM Match m JOIN League l ON m.league_id = l.id WHERE m.season = '2008/2009' GROUP BY l.name ORDER BY COUNT(*) DESC LIMIT 1	european_football_2
SELECT SUM(t2.overall_rating) / COUNT(t1.id) FROM Player AS t1 INNER JOIN Player_Attributes AS t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE strftime('%Y', t1.birthday) < '1986'	european_football_2
SELECT (SUM(CASE WHEN t1.player_name = 'Ariel Borysiuk' THEN t2.overall_rating ELSE 0 END) * 1.0 - SUM(CASE WHEN t1.player_name = 'Paulin Puel' THEN t2.overall_rating ELSE 0 END)) * 100 / SUM(CASE WHEN t1.player_name = 'Paulin Puel' THEN t2.overall_rating ELSE 0 END) AS percentage_difference FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name IN ('Ariel Borysiuk', 'Paulin Puel')	european_football_2
SELECT CAST(SUM(t2.buildUpPlaySpeed) AS REAL) / COUNT(t2.id) FROM Team t1 JOIN Team_Attributes t2 ON t1.team_api_id = t2.team_api_id WHERE t1.team_long_name = 'Heart of Midlothian'	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_api_id = t2.player_api_id WHERE t1.player_name = 'Pietro Marino'	european_football_2
SELECT SUM(pa.crossing) FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Aaron Lennox'	european_football_2
SELECT ta.chanceCreationPassing, ta.chanceCreationPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Ajax' ORDER BY ta.chanceCreationPassing DESC LIMIT 1	european_football_2
SELECT DISTINCT pa.preferred_foot FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Abdou Diallo'	european_football_2
SELECT MAX(t2.overall_rating) FROM Player AS t1 INNER JOIN Player_Attributes AS t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE t1.player_name = 'Dorlan Pabon'	european_football_2
SELECT CAST(SUM(T1.away_team_goal) AS REAL) / COUNT(T1.id) FROM Match AS T1 JOIN Team AS T2 ON T1.away_team_api_id = T2.team_api_id JOIN League AS T3 ON T1.league_id = T3.id WHERE T2.team_long_name = 'Parma' AND T3.name = 'Italy Serie A'	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE pa.overall_rating = 77 AND pa.date LIKE '2016-06-23%' ORDER BY CAST(p.birthday AS INTEGER) ASC LIMIT 1	european_football_2
SELECT pa.overall_rating FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Aaron Mooy' AND pa.date LIKE '2016-02-04%'	european_football_2
SELECT pa.potential FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Francesco Parravicini' AND pa.date = '2010-08-30 00:00:00'	european_football_2
SELECT pa.attacking_work_rate FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Francesco Migliore' AND pa.date LIKE '2015-05-01%'	european_football_2
SELECT pa.defensive_work_rate FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Kevin Berigaud' AND pa.date = '2013-02-22 00:00:00'	european_football_2
SELECT pa.date FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE p.player_name = 'Kevin Constant' ORDER BY pa.crossing DESC LIMIT 1	european_football_2
SELECT ta.buildUpPlaySpeedClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Willem II' AND ta.date = '2011-02-22 00:00:00'	european_football_2
SELECT ta.buildUpPlayDribblingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_short_name = 'LEI' AND ta.date = '2015-09-10 00:00:00'	european_football_2
SELECT ta.buildUpPlayPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'FC Lorient' AND ta.date LIKE '2010-02-22%'	european_football_2
SELECT ta.chanceCreationPassingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'PEC Zwolle' AND ta.date = '2013-09-20 00:00:00'	european_football_2
SELECT ta.chanceCreationCrossingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Hull City' AND ta.date = '2010-02-22 00:00:00'	european_football_2
SELECT ta.chanceCreationShootingClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'Hannover 96' AND ta.date LIKE '2015-09-10%'	european_football_2
SELECT CAST(SUM(t2.overall_rating) AS REAL) / COUNT(t2.id) FROM Player t1 JOIN Player_Attributes t2 ON t1.player_fifa_api_id = t2.player_fifa_api_id WHERE t1.player_name = 'Marko Arnautovic' AND SUBSTR(t2.date, 1, 10) BETWEEN '2007-02-22' AND '2016-04-21'	european_football_2
SELECT CAST((ld_pa.overall_rating - jb_pa.overall_rating) AS REAL) * 100 / ld_pa.overall_rating AS LvsJ_percent FROM Player_Attributes ld_pa JOIN Player ld ON ld.player_api_id = ld_pa.player_api_id JOIN Player_Attributes jb_pa ON jb_pa.date = ld_pa.date JOIN Player jb ON jb.player_api_id = jb_pa.player_api_id WHERE ld.player_name = 'Landon Donovan' AND jb.player_name = 'Jordan Bowery' AND ld_pa.date LIKE '2013-07-12%'	european_football_2
SELECT player_name FROM Player WHERE height = (SELECT MAX(height) FROM Player)	european_football_2
SELECT player_api_id FROM Player ORDER BY weight DESC LIMIT 10	european_football_2
SELECT player_name FROM Player WHERE (strftime('%Y', 'now') - strftime('%Y', birthday)) - (strftime('%m-%d', 'now') < strftime('%m-%d', birthday)) >= 35	european_football_2
SELECT SUM(m.home_team_goal) FROM Match m JOIN Player p ON m.away_player_9 = p.player_api_id WHERE p.player_name = 'Aaron Lennon'	european_football_2
SELECT SUM(m.away_team_goal) FROM Match m JOIN Player p ON ( p.player_api_id IN (m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11) ) WHERE p.player_name IN ('Daan Smith', 'Filipe Ferreira')	european_football_2
WITH young_players AS ( SELECT player_api_id FROM Player WHERE CAST(strftime('%Y', 'now') AS INTEGER) - CAST(SUBSTR(birthday, 1, 4) AS INTEGER) <= 30 ) SELECT SUM(home_team_goal) AS "SUM(t2.home_team_goal)" FROM Match WHERE home_player_1 IN (SELECT player_api_id FROM young_players) OR home_player_2 IN (SELECT player_api_id FROM young_players) OR home_player_3 IN (SELECT player_api_id FROM young_players) OR home_player_4 IN (SELECT player_api_id FROM young_players) OR home_player_5 IN (SELECT player_api_id FROM young_players) OR home_player_6 IN (SELECT player_api_id FROM young_players) OR home_player_7 IN (SELECT player_api_id FROM young_players) OR home_player_8 IN (SELECT player_api_id FROM young_players) OR home_player_9 IN (SELECT player_api_id FROM young_players) OR home_player_10 IN (SELECT player_api_id FROM young_players) OR home_player_11 IN (SELECT player_api_id FROM young_players)	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.potential = (SELECT MAX(potential) FROM Player_Attributes)	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.attacking_work_rate = 'high'	european_football_2
SELECT p.player_name FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id WHERE pa.finishing = 1 ORDER BY p.birthday ASC LIMIT 1	european_football_2
SELECT DISTINCT p.player_name FROM Player p JOIN Match m ON p.player_api_id IN ( m.home_player_1, m.home_player_2, m.home_player_3, m.home_player_4, m.home_player_5, m.home_player_6, m.home_player_7, m.home_player_8, m.home_player_9, m.home_player_10, m.home_player_11, m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11 ) JOIN League l ON m.league_id = l.id WHERE l.name = 'Belgium Jupiler League'	european_football_2
SELECT DISTINCT c.name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id JOIN Match m ON p.player_api_id IN ( m.home_player_1, m.home_player_2, m.home_player_3, m.home_player_4, m.home_player_5, m.home_player_6, m.home_player_7, m.home_player_8, m.home_player_9, m.home_player_10, m.home_player_11, m.away_player_1, m.away_player_2, m.away_player_3, m.away_player_4, m.away_player_5, m.away_player_6, m.away_player_7, m.away_player_8, m.away_player_9, m.away_player_10, m.away_player_11 ) JOIN Country c ON m.country_id = c.id WHERE pa.vision > 89	european_football_2
SELECT c.name FROM ( SELECT country_id, home_player_1 as player_api_id FROM Match WHERE home_player_1 IS NOT NULL UNION ALL SELECT country_id, home_player_2 as player_api_id FROM Match WHERE home_player_2 IS NOT NULL UNION ALL SELECT country_id, home_player_3 as player_api_id FROM Match WHERE home_player_3 IS NOT NULL UNION ALL SELECT country_id, home_player_4 as player_api_id FROM Match WHERE home_player_4 IS NOT NULL UNION ALL SELECT country_id, home_player_5 as player_api_id FROM Match WHERE home_player_5 IS NOT NULL UNION ALL SELECT country_id, home_player_6 as player_api_id FROM Match WHERE home_player_6 IS NOT NULL UNION ALL SELECT country_id, home_player_7 as player_api_id FROM Match WHERE home_player_7 IS NOT NULL UNION ALL SELECT country_id, home_player_8 as player_api_id FROM Match WHERE home_player_8 IS NOT NULL UNION ALL SELECT country_id, home_player_9 as player_api_id FROM Match WHERE home_player_9 IS NOT NULL UNION ALL SELECT country_id, home_player_10 as player_api_id FROM Match WHERE home_player_10 IS NOT NULL UNION ALL SELECT country_id, home_player_11 as player_api_id FROM Match WHERE home_player_11 IS NOT NULL UNION ALL SELECT country_id, away_player_1 as player_api_id FROM Match WHERE away_player_1 IS NOT NULL UNION ALL SELECT country_id, away_player_2 as player_api_id FROM Match WHERE away_player_2 IS NOT NULL UNION ALL SELECT country_id, away_player_3 as player_api_id FROM Match WHERE away_player_3 IS NOT NULL UNION ALL SELECT country_id, away_player_4 as player_api_id FROM Match WHERE away_player_4 IS NOT NULL UNION ALL SELECT country_id, away_player_5 as player_api_id FROM Match WHERE away_player_5 IS NOT NULL UNION ALL SELECT country_id, away_player_6 as player_api_id FROM Match WHERE away_player_6 IS NOT NULL UNION ALL SELECT country_id, away_player_7 as player_api_id FROM Match WHERE away_player_7 IS NOT NULL UNION ALL SELECT country_id, away_player_8 as player_api_id FROM Match WHERE away_player_8 IS NOT NULL UNION ALL SELECT country_id, away_player_9 as player_api_id FROM Match WHERE away_player_9 IS NOT NULL UNION ALL SELECT country_id, away_player_10 as player_api_id FROM Match WHERE away_player_10 IS NOT NULL UNION ALL SELECT country_id, away_player_11 as player_api_id FROM Match WHERE away_player_11 IS NOT NULL ) AS player_matches JOIN Player p ON player_matches.player_api_id = p.player_api_id JOIN Country c ON player_matches.country_id = c.id GROUP BY c.name ORDER BY AVG(p.weight) DESC LIMIT 1	european_football_2
SELECT DISTINCT t.team_long_name FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE ta.buildUpPlaySpeedClass = 'Slow'	european_football_2
SELECT DISTINCT t.team_short_name FROM Team_Attributes ta JOIN Team t ON ta.team_api_id = t.team_api_id WHERE ta.chanceCreationPassingClass = 'Safe'	european_football_2
SELECT CAST(SUM(T1.height) AS REAL) / COUNT(T1.id) FROM Player AS T1 JOIN Match AS T2 ON T1.player_api_id IN ( T2.home_player_1, T2.home_player_2, T2.home_player_3, T2.home_player_4, T2.home_player_5, T2.home_player_6, T2.home_player_7, T2.home_player_8, T2.home_player_9, T2.home_player_10, T2.home_player_11, T2.away_player_1, T2.away_player_2, T2.away_player_3, T2.away_player_4, T2.away_player_5, T2.away_player_6, T2.away_player_7, T2.away_player_8, T2.away_player_9, T2.away_player_10, T2.away_player_11 ) JOIN League AS T3 ON T2.league_id = T3.id JOIN Country AS T4 ON T3.country_id = T4.id WHERE T4.name = 'Italy'	european_football_2
SELECT player_name FROM Player WHERE height > 180 ORDER BY player_name LIMIT 3	european_football_2
SELECT COUNT(id) FROM Player WHERE player_name LIKE 'Aaron%' AND CAST(birthday AS INTEGER) > 1990	european_football_2
SELECT SUM(CASE WHEN t1.id = 6 THEN t1.jumping ELSE 0 END) - SUM(CASE WHEN t1.id = 23 THEN t1.jumping ELSE 0 END) AS "SUM(CASE WHEN t1.id = 6 THEN t1.jumping ELSE 0 END) - SUM(CASE WHEN t1.id = 23 THEN t1.jumping ELSE 0 END)" FROM Player_Attributes t1	european_football_2
SELECT id FROM Player_Attributes WHERE preferred_foot = 'right' ORDER BY potential ASC LIMIT 5	european_football_2
SELECT COUNT(t1.id) FROM Player_Attributes t1 WHERE t1.preferred_foot = 'left' AND t1.crossing = ( SELECT MAX(crossing) FROM Player_Attributes WHERE preferred_foot = 'left' )	european_football_2
SELECT CAST(COUNT(CASE WHEN strength > 80 AND stamina > 80 THEN id ELSE NULL END) AS REAL) * 100 / COUNT(id) FROM Player_Attributes	european_football_2
SELECT c.name FROM League l JOIN Country c ON l.country_id = c.id WHERE l.name = 'Poland Ekstraklasa'	european_football_2
SELECT m.home_team_goal, m.away_team_goal FROM Match m JOIN League l ON m.league_id = l.id WHERE l.name = 'Belgium Jupiler League' AND m.date LIKE '2008-09-24%'	european_football_2
SELECT DISTINCT pa.sprint_speed, pa.agility, pa.acceleration FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.player_name = 'Alexis Blin'	european_football_2
SELECT ta.buildUpPlaySpeedClass FROM Team t JOIN Team_Attributes ta ON t.team_api_id = ta.team_api_id WHERE t.team_long_name = 'KSV Cercle Brugge' ORDER BY CAST(ta.date AS INTEGER) DESC LIMIT 1	european_football_2
SELECT COUNT(t2.id) FROM Match t2 JOIN League t3 ON t2.league_id = t3.id WHERE t2.season = '2015/2016' AND t3.name = 'Italy Serie A'	european_football_2
SELECT MAX(t2.home_team_goal) FROM League t1 JOIN Match t2 ON t1.id = t2.league_id WHERE t1.name = 'Netherlands Eredivisie'	european_football_2
SELECT pa.id, pa.finishing, pa.curve FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id WHERE p.weight = (SELECT MAX(weight) FROM Player) LIMIT 1	european_football_2
SELECT League.name FROM Match JOIN League ON Match.league_id = League.id WHERE Match.season = '2015/2016' GROUP BY League.name ORDER BY COUNT(Match.id) DESC LIMIT 4	european_football_2
SELECT t.team_long_name FROM Match m JOIN Team t ON m.away_team_api_id = t.team_api_id ORDER BY m.away_team_goal DESC LIMIT 1	european_football_2
SELECT p.player_name FROM Player_Attributes pa JOIN Player p ON pa.player_api_id = p.player_api_id ORDER BY pa.overall_rating DESC LIMIT 1	european_football_2
SELECT CAST(COUNT(CASE WHEN p.height < 180 AND pa.strength > 70 THEN 1 END) AS REAL) * 100 / COUNT(*) AS percent FROM Player p JOIN Player_Attributes pa ON p.player_api_id = pa.player_api_id	european_football_2
SELECT CAST(SUM(CASE WHEN Admission = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN Admission = '-' THEN 1 ELSE 0 END) FROM Patient WHERE SEX = 'M'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN STRFTIME('%Y', Birthday) > '1930' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient WHERE SEX = 'F'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN Admission = '+' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient WHERE Birthday BETWEEN '1930-01-01' AND '1940-12-31'	thrombosis_prediction
SELECT SUM(CASE WHEN "Admission" = '+' THEN 1.0 ELSE 0 END) / SUM(CASE WHEN "Admission" = '-' THEN 1 ELSE 0 END) FROM Patient WHERE TRIM("Diagnosis") = 'SLE' AND "Admission" IS NOT NULL AND "Admission" != ''	thrombosis_prediction
SELECT p.Diagnosis, l.Date FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.ID = 30609	thrombosis_prediction
SELECT p.SEX, p.Birthday, e."Examination Date", e.Symptoms FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE p.ID = 163109	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.LDH > 500	thrombosis_prediction
SELECT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T2.Birthday) FROM Examination AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.RVVT = '+'	thrombosis_prediction
SELECT p.ID, p.SEX, p.Diagnosis FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE e.Thrombosis = 2	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p.Birthday) = '1937' AND l."T-CHO" >= 250	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.ALB < 3.5	thrombosis_prediction
SELECT (CAST(SUM(CASE WHEN T1.SEX = 'F' AND (T2.TP < 6.0 OR T2.TP > 8.5) THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*)) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID	thrombosis_prediction
SELECT AVG(T2.`aCL IgG`) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND (CAST(strftime('%Y', 'now') AS INTEGER) - CAST(strftime('%Y', T1.Birthday) AS INTEGER)) >= 50	thrombosis_prediction
SELECT COUNT(*) FROM Patient WHERE SEX = 'F' AND STRFTIME('%Y', Description) = '1997' AND Admission = '-'	thrombosis_prediction
SELECT MIN(STRFTIME('%Y', `First Date`) - STRFTIME('%Y', Birthday)) FROM Patient	thrombosis_prediction
SELECT COUNT(*) FROM Patient JOIN Examination ON Patient.ID = Examination.ID WHERE STRFTIME('%Y', Examination."Examination Date") = '1997' AND Examination.Thrombosis = 1 AND Patient.SEX = 'F'	thrombosis_prediction
SELECT STRFTIME('%Y', MAX(Patient.Birthday)) - STRFTIME('%Y', MIN(Patient.Birthday)) FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.TG >= 200	thrombosis_prediction
SELECT e."Symptoms", p."Diagnosis" FROM Examination e JOIN Patient p ON e."ID" = p."ID" WHERE e."Symptoms" IS NOT NULL ORDER BY p."Birthday" DESC LIMIT 1	thrombosis_prediction
SELECT CAST(COUNT(T1.ID) AS REAL) / 12 FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T2.SEX = 'M' AND T1.Date BETWEEN '1998-01-01' AND '1998-12-31'	thrombosis_prediction
SELECT T1.Date, STRFTIME('%Y', T2.`First Date`) - STRFTIME('%Y', T2.Birthday), T2.Birthday FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T2.Diagnosis LIKE '%SJS%' ORDER BY T2.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.UA <= 8.0 AND T1.SEX = 'M' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN T2.UA <= 6.5 AND T1.SEX = 'F' THEN 1 ELSE 0 END) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX IN ('M', 'F') AND T2.UA IS NOT NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 LEFT JOIN Examination AS T2 ON T1.ID = T2.ID WHERE CAST(STRFTIME('%Y', T2."Examination Date") AS INTEGER) - CAST(STRFTIME('%Y', T1."First Date") AS INTEGER) >= 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE strftime('%Y', T2."Examination Date") BETWEEN '1990' AND '1993' AND CAST(strftime('%Y', T2."Examination Date") AS INTEGER) - CAST(strftime('%Y', T1.Birthday) AS INTEGER) < 18	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2."T-BIL" >= 2.0	thrombosis_prediction
SELECT Diagnosis FROM Examination WHERE "Examination Date" BETWEEN '1985-01-01' AND '1995-12-31' GROUP BY Diagnosis ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT AVG(1999 - CAST(STRFTIME('%Y', T2.Birthday) AS INTEGER)) FROM Laboratory AS T1 INNER JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.Date BETWEEN '1991-10-01' AND '1991-10-31'	thrombosis_prediction
SELECT STRFTIME('%Y', T2.Date) - STRFTIME('%Y', T1.Birthday), T1.Diagnosis FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID ORDER BY T2.HGB DESC LIMIT 1	thrombosis_prediction
SELECT ANA FROM Examination WHERE ID = 3605340 AND "Examination Date" = '1996-12-02'	thrombosis_prediction
SELECT CASE WHEN "T-CHO" < 250 THEN 'Normal' ELSE 'Abnormal' END FROM Laboratory WHERE ID = 2927464 AND Date = '1995-09-04'	thrombosis_prediction
SELECT SEX FROM Patient WHERE TRIM(Diagnosis) = 'AORTITIS' ORDER BY ID LIMIT 1	thrombosis_prediction
SELECT e."aCL IgA", e."aCL IgG", e."aCL IgM" FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE p.Diagnosis = 'SLE' AND p.Description = '1994-02-19' AND e."Examination Date" = '1993-11-12'	thrombosis_prediction
SELECT p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GPT = 9 AND l.Date = '1992-06-12'	thrombosis_prediction
SELECT STRFTIME('%Y', T2.Date) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.UA = 8.4 AND T2.Date = '1991-10-21'	thrombosis_prediction
SELECT COUNT(*) FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p."First Date" = '1991-06-13' AND TRIM(p.Diagnosis) = 'SJS' AND STRFTIME('%Y', l.Date) = '1995'	thrombosis_prediction
SELECT p.Diagnosis FROM Examination e JOIN Patient p ON e.ID = p.ID WHERE e.Diagnosis = 'SLE' AND e.`Examination Date` = '1997-01-27'	thrombosis_prediction
SELECT e."Symptoms" FROM Patient p JOIN Examination e ON p."ID" = e."ID" WHERE p."Birthday" = '1959-03-01' AND e."Examination Date" = '1993-09-27'	thrombosis_prediction
SELECT CAST((SUM(CASE WHEN T1.Date LIKE '1981-11-%' THEN T1."T-CHO" ELSE 0 END) - SUM(CASE WHEN T1.Date LIKE '1981-12-%' THEN T1."T-CHO" ELSE 0 END)) AS REAL) / NULLIF(SUM(CASE WHEN T1.Date LIKE '1981-12-%' THEN T1."T-CHO" ELSE 0 END), 0) FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T2.Birthday = '1959-02-18'	thrombosis_prediction
SELECT p.ID FROM Patient p JOIN Examination e ON p.ID = e.ID WHERE TRIM(p."Diagnosis") LIKE '%BEHCET%' AND date(e."Examination Date") >= '1997-01-01' AND date(e."Examination Date") <= '1997-12-31'	thrombosis_prediction
SELECT DISTINCT ID FROM Laboratory WHERE Date BETWEEN '1987-07-06' AND '1996-01-31' AND GPT > 30 AND ALB < 4	thrombosis_prediction
SELECT ID FROM Patient WHERE SEX = 'F' AND STRFTIME('%Y', Birthday) = '1964' AND Admission = '+'	thrombosis_prediction
SELECT COUNT(*) FROM Examination WHERE Thrombosis = 2 AND "ANA Pattern" = 'S' AND "aCL IgM" > (SELECT AVG("aCL IgM") * 1.2 FROM Examination)	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN UA <= 6.5 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Laboratory WHERE "U-PRO" > 0 AND "U-PRO" < 30	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN TRIM("Diagnosis") = 'BEHCET' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Patient WHERE "SEX" = 'M' AND STRFTIME('%Y', "First Date") = '1981'	thrombosis_prediction
SELECT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Admission = '-' AND l.Date LIKE '1991-10%' AND l."T-BIL" < 2.0	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND T2."ANA Pattern" != 'P' AND STRFTIME('%Y', T1.Birthday) BETWEEN '1980' AND '1989'	thrombosis_prediction
SELECT p.SEX FROM Patient p JOIN Examination e ON p.ID = e.ID JOIN Laboratory l ON p.ID = l.ID WHERE e.Diagnosis = 'PSS' AND l.CRP = '2+' AND l.CRE = 1 AND l.LDH = 123	thrombosis_prediction
SELECT AVG(T2.ALB) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND T2.PLT > 400 AND TRIM(T1.Diagnosis) = 'SLE'	thrombosis_prediction
SELECT "Symptoms" FROM "Examination" WHERE "Diagnosis" LIKE '%SLE%' AND "Symptoms" IS NOT NULL GROUP BY "Symptoms" ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT "First Date", "Diagnosis" FROM Patient WHERE ID = 48473	thrombosis_prediction
SELECT COUNT(ID) FROM Patient WHERE SEX = 'F' AND TRIM(Diagnosis) = 'APS'	thrombosis_prediction
SELECT COUNT(ID) FROM Laboratory WHERE STRFTIME('%Y', Date) = '1997' AND (TP <= 6 OR TP >= 8.5)	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN Diagnosis = 'SLE' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Examination WHERE Symptoms LIKE '%thrombocytopenia%'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN SEX = 'F' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(ID) FROM Patient WHERE STRFTIME('%Y', Birthday) = '1980' AND Diagnosis = 'RA'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2."Examination Date" BETWEEN '1995-01-01' AND '1997-12-31' AND T2.Diagnosis LIKE '%Behcet%' AND T1.Admission = '-'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F' AND T2.WBC < 3.5	thrombosis_prediction
SELECT STRFTIME('%d', T3.`Examination Date`) - STRFTIME('%d', T1.`First Date`) FROM Patient AS T1 JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T1.ID = 821298	thrombosis_prediction
SELECT CASE WHEN (T1.SEX = 'F' AND T2.UA > 6.5) OR (T1.SEX = 'M' AND T2.UA > 8.0) THEN true ELSE false END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.ID = 57266	thrombosis_prediction
SELECT Date FROM Laboratory WHERE ID = 48473 AND GOT >= 60	thrombosis_prediction
SELECT DISTINCT p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.GOT < 60 AND STRFTIME('%Y', l.Date) = '1994'	thrombosis_prediction
SELECT DISTINCT Patient.ID FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Patient.SEX = 'M' AND Laboratory.GPT >= 60	thrombosis_prediction
SELECT Patient.Diagnosis FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.GPT > 60 ORDER BY Patient.Birthday ASC	thrombosis_prediction
SELECT AVG(LDH) FROM Laboratory WHERE LDH < 500	thrombosis_prediction
SELECT DISTINCT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.LDH BETWEEN 600 AND 800	thrombosis_prediction
SELECT DISTINCT p.Admission FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.ALP < 300	thrombosis_prediction
SELECT DISTINCT T1.ID, CASE WHEN T2.ALP < 300 THEN 'normal' ELSE 'abNormal' END FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Birthday = '1982-04-01'	thrombosis_prediction
SELECT DISTINCT Patient.ID, Patient.SEX, Patient.Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.TP < 6.0	thrombosis_prediction
SELECT Laboratory.TP - 8.5 AS "TP - 8.5" FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Patient.SEX = 'F' AND Laboratory.TP > 8.5	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.SEX = 'M' AND (l.ALB <= 3.5 OR l.ALB >= 5.5) ORDER BY p.Birthday DESC	thrombosis_prediction
SELECT CASE WHEN T2.ALB >= 3.5 AND T2.ALB <= 5.5 THEN 'normal' ELSE 'abnormal' END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE STRFTIME('%Y', T1.Birthday) = '1982'	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.UA > 6.5 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'F'	thrombosis_prediction
SELECT AVG(T2.UA) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE (T1.SEX = 'M' AND T2.UA < 8.0) OR (T1.SEX = 'F' AND T2.UA < 6.5) AND T2.Date = ( SELECT MAX(T3.Date) FROM Laboratory AS T3 WHERE T3.ID = T1.ID ) AND T1.SEX IS NOT NULL AND T1.SEX != '' AND T2.UA IS NOT NULL	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.UN = 29	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE TRIM(p.Diagnosis) = 'RA' AND l.UN < 30	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.CRE >= 1.5	thrombosis_prediction
SELECT CASE WHEN SUM(CASE WHEN T1.SEX = 'M' THEN 1 ELSE 0 END) > SUM(CASE WHEN T1.SEX = 'F' THEN 1 ELSE 0 END) THEN 'True' ELSE 'False' END FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.CRE >= 1.5 AND T1.SEX IN ('M', 'F')	thrombosis_prediction
SELECT l."T-BIL", p."ID", p."SEX", p."Birthday" FROM Laboratory l JOIN Patient p ON l."ID" = p."ID" WHERE l."T-BIL" IS NOT NULL ORDER BY l."T-BIL" DESC LIMIT 1	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l."T-BIL" >= 2.0	thrombosis_prediction
SELECT p.ID, l."T-CHO" FROM Patient p JOIN Laboratory l ON p.ID = l.ID ORDER BY l."T-CHO" DESC, p.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT AVG(STRFTIME('%Y', date('NOW')) - STRFTIME('%Y', T1.Birthday)) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2."T-CHO" >= 250	thrombosis_prediction
SELECT DISTINCT p.ID, p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.TG > 300	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.TG >= 200 AND CAST(strftime('%Y', 'now') - strftime('%Y', T1.Birthday) AS INTEGER) > 50	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Admission = '-' AND l.CPK < 250	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND STRFTIME('%Y', T1.Birthday) BETWEEN '1936' AND '1956' AND T2.CPK >= 250	thrombosis_prediction
SELECT DISTINCT T1.ID, T1.SEX, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.GLU >= 180 AND T2."T-CHO" < 250	thrombosis_prediction
SELECT p.ID, l.GLU FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p.Description) = '1991' AND l.GLU < 180	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX, p.Birthday FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.WBC <= 3.5 OR l.WBC >= 9.0 ORDER BY p.SEX, (julianday('now') - julianday(p.Birthday)) ASC	thrombosis_prediction
SELECT DISTINCT T1.Diagnosis, T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.RBC < 3.5	thrombosis_prediction
SELECT DISTINCT p.ID, p.Admission FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.SEX = 'F' AND CAST(strftime('%Y', 'now') AS INTEGER) - CAST(strftime('%Y', p.Birthday) AS INTEGER) >= 50 AND (l.RBC <= 3.5 OR l.RBC >= 6.0)	thrombosis_prediction
SELECT DISTINCT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Admission = '-' AND l.HGB < 10 AND p.Admission IS NOT NULL AND p.Admission != '' AND p.SEX IS NOT NULL AND p.SEX != ''	thrombosis_prediction
SELECT p.ID, p.SEX FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE TRIM(p.Diagnosis) = 'SLE' AND l.HGB > 10 AND l.HGB < 17 ORDER BY p.Birthday ASC LIMIT 1	thrombosis_prediction
SELECT T1.ID, STRFTIME('%Y', CURRENT_TIMESTAMP) - STRFTIME('%Y', T1.Birthday) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.HCT >= 52 GROUP BY T1.ID HAVING COUNT(T2.ID) >= 2	thrombosis_prediction
SELECT AVG(HCT) FROM Laboratory WHERE STRFTIME('%Y', Date) = '1991' AND HCT < 29	thrombosis_prediction
SELECT SUM(CASE WHEN PLT <= 100 THEN 1 ELSE 0 END) - SUM(CASE WHEN PLT >= 400 THEN 1 ELSE 0 END) FROM Laboratory	thrombosis_prediction
SELECT DISTINCT p.ID FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE STRFTIME('%Y', l.Date) = '1984' AND CAST(STRFTIME('%Y', 'now') AS INTEGER) - CAST(STRFTIME('%Y', p.Birthday) AS INTEGER) < 50 AND l.PLT BETWEEN 100 AND 400	thrombosis_prediction
SELECT CAST(SUM(CASE WHEN T2.PT >= 14 AND T1.SEX = 'F' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(*) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE (strftime('%Y', 'now') - strftime('%Y', T1.Birthday)) > 55 AND T2.PT IS NOT NULL	thrombosis_prediction
SELECT DISTINCT Patient.ID FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE strftime('%Y', Patient."First Date") > '1992' AND Laboratory.PT IS NOT NULL AND Laboratory.PT < 14	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Examination AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID AND T1."Examination Date" = T2.Date WHERE T1."Examination Date" > '1997-01-01' AND T2.APTT >= 45	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.APTT > 45 AND T2.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.WBC > 3.5 AND T2.WBC < 9.0 AND (T2.FG <= 150 OR T2.FG >= 450)	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Birthday > '1980-01-01' AND (T2.FG < 150 OR T2.FG > 450)	thrombosis_prediction
SELECT DISTINCT p."Diagnosis" FROM Patient p JOIN Laboratory l ON p."ID" = l."ID" WHERE l."U-PRO" IN ('30', '100', '300', '>=300', '>=1000')	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE p.Diagnosis = 'SLE' AND l."U-PRO" > '0' AND l."U-PRO" < '30'	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 WHERE T1.IGG >= 2000	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.IGG > 900 AND T1.IGG < 2000 AND T2.Symptoms IS NOT NULL	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.IGA BETWEEN 80 AND 500 ORDER BY l.IGA DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.IGA > 80 AND T2.IGA < 500 AND STRFTIME('%Y', T1."First Date") >= '1990'	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.IGM IS NOT NULL AND (l.IGM <= 40 OR l.IGM >= 400) GROUP BY p.Diagnosis ORDER BY COUNT(*) DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.CRP = '+' AND T1.Description IS NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.CRE >= 1.5 AND (strftime('%Y', 'now') - strftime('%Y', T2.Birthday)) < 70	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.RA IN ('-', '+-') AND T1.KCT = '+'	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE STRFTIME('%Y', p.Birthday) >= '1985' AND l.RA IN ('-', '+-')	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE (strftime('%Y', 'now') - strftime('%Y', p.Birthday)) > 60 AND ( CASE WHEN l.RF LIKE '<%' THEN CAST(SUBSTR(l.RF, 2) AS REAL) ELSE CAST(l.RF AS REAL) END ) < 20	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID INNER JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T2.RF = '-' AND T3.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID JOIN Examination AS T3 ON T1.ID = T3.ID WHERE T2.C3 > 35 AND T3."ANA Pattern" = 'P'	thrombosis_prediction
SELECT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE l.HCT <= 29 OR l.HCT >= 52 ORDER BY e."aCL IgA" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID JOIN Laboratory AS T3 ON T1.ID = T3.ID WHERE T2.Thrombosis = 1 AND T3.C4 > 10	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE (T2.RNP = 'negative' OR T2.RNP = '0') AND T1.Admission = '+'	thrombosis_prediction
SELECT MAX(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.RNP NOT IN ('-', '+-')	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SM IN ('-', '0') AND T2.Thrombosis = 0	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.SM NOT IN ('negative', '0') ORDER BY p.Birthday DESC LIMIT 3	thrombosis_prediction
SELECT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID AND e."Examination Date" = l.Date WHERE e."Examination Date" > '1997-01-01' AND l.SC170 IN ('negative', '0')	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID INNER JOIN Laboratory AS T3 ON T1.ID = T3.ID WHERE T1.SEX = 'F' AND T3."SC170" IN ('negative', '0') AND T2."Symptoms" IS NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.SSA IN ('-', '+-') AND STRFTIME('%Y', T1.`First Date`) < '2000'	thrombosis_prediction
SELECT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.SSA NOT IN ('negative', '0') ORDER BY p."First Date" ASC LIMIT 1	thrombosis_prediction
SELECT COUNT(DISTINCT p.ID) FROM Patient p JOIN Examination e ON p.ID = e.ID JOIN Laboratory l ON p.ID = l.ID WHERE l.SSB IN ('negative', '0') AND e.Diagnosis = 'SLE'	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.SSB IN ('negative', '0') AND T2.Symptoms IS NOT NULL	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.CENTROMEA IN ('-', '+-') AND T2.SSB IN ('-', '+-')	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE CAST(l.DNA AS INTEGER) >= 8	thrombosis_prediction
SELECT COUNT(DISTINCT T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Description IS NULL AND CAST(T2.DNA AS INTEGER) < 8	thrombosis_prediction
SELECT COUNT(Patient.ID) FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.IGG > 900 AND Laboratory.IGG < 2000 AND Patient.Admission = '+'	thrombosis_prediction
SELECT COUNT(CASE WHEN T1.Diagnosis LIKE '%SLE%' THEN T1.ID ELSE 0 END) / COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.GOT >= 60	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.GOT < 60	thrombosis_prediction
SELECT MAX(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.GOT >= 60	thrombosis_prediction
SELECT p."Birthday" FROM Patient p JOIN Laboratory l ON p."ID" = l."ID" WHERE l."GPT" < 60 ORDER BY l."GPT" DESC LIMIT 3	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.GOT < 60	thrombosis_prediction
SELECT p."First Date" FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.LDH < 500 ORDER BY l.LDH DESC LIMIT 1	thrombosis_prediction
SELECT p."First Date" FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.LDH >= 500 ORDER BY p."First Date" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T2.ALP >= 300 AND T1.Admission = '+'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '-' AND T2.ALP < 300	thrombosis_prediction
SELECT p.Diagnosis FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE l.TP < 6.0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Diagnosis = 'SJS' AND T2.TP > 6.0 AND T2.TP < 8.5 Wait, but I need to verify this SQL first. Let me use verify_sql to check. Action: verify_sql Action Input: SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Diagnosis = 'SJS' AND T2.TP > 6.0 AND T2.TP < 8.5	thrombosis_prediction
SELECT Date FROM Laboratory WHERE ALB > 3.5 AND ALB < 5.5 ORDER BY ALB DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.ALB IS NOT NULL AND T2.ALB > 3.5 AND T2.ALB < 5.5 AND T2.TP IS NOT NULL AND T2.TP BETWEEN 6.0 AND 8.5	thrombosis_prediction
SELECT e."aCL IgG", e."aCL IgM", e."aCL IgA" FROM Patient p JOIN Laboratory l ON p.ID = l.ID JOIN Examination e ON p.ID = e.ID WHERE p.SEX = 'F' AND l.UA > 6.50 ORDER BY l.UA DESC LIMIT 1	thrombosis_prediction
SELECT MAX(e.ANA) AS ANA FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE l.CRE < 1.5	thrombosis_prediction
SELECT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE l.CRE < 1.5 ORDER BY e."aCL IgA" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-BIL" >= 2.0 AND T2."ANA Pattern" LIKE '%P%'	thrombosis_prediction
SELECT e.ANA FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE l."T-BIL" < 2.0 ORDER BY l."T-BIL" DESC LIMIT 1	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-CHO" >= 250 AND T2.KCT = '-'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1."T-CHO" < 250 AND T2."ANA Pattern" = 'P'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 INNER JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.TG < 200 AND T2."Symptoms" IS NOT NULL	thrombosis_prediction
SELECT p.Diagnosis FROM Laboratory l JOIN Patient p ON l.ID = p.ID WHERE l.TG < 200 ORDER BY l.TG DESC LIMIT 1	thrombosis_prediction
SELECT DISTINCT e.ID FROM Examination e JOIN Laboratory l ON e.ID = l.ID WHERE e.Thrombosis = 0 AND l.CPK < 250	thrombosis_prediction
SELECT COUNT(Laboratory.ID) FROM Laboratory JOIN Examination ON Laboratory.ID = Examination.ID WHERE Laboratory.CPK < 250 AND (Examination.KCT = '+' OR Examination.RVVT = '+' OR Examination.LAC = '+')	thrombosis_prediction
SELECT MIN(Patient.Birthday) AS Birthday FROM Patient JOIN Laboratory ON Patient.ID = Laboratory.ID WHERE Laboratory.GLU > 180	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 JOIN Examination AS T2 ON T1.ID = T2.ID WHERE T1.GLU < 180 AND T2.Thrombosis = 0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.Admission = '+' AND T2.WBC BETWEEN 3.5 AND 9.0	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE TRIM(T1.Diagnosis) = 'SLE' AND T2.WBC BETWEEN 3.5 AND 9.0	thrombosis_prediction
SELECT DISTINCT p.ID FROM Patient p JOIN Laboratory l ON p.ID = l.ID WHERE (l.RBC <= 3.5 OR l.RBC >= 6.0) AND p.Admission = '-'	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Laboratory AS T1 JOIN Patient AS T2 ON T1.ID = T2.ID WHERE T1.PLT > 100 AND T1.PLT < 400 AND T2.Diagnosis IS NOT NULL	thrombosis_prediction
SELECT Laboratory.PLT FROM Laboratory JOIN Patient ON Laboratory.ID = Patient.ID WHERE Patient.Diagnosis = 'MCTD' AND Laboratory.PLT > 100 AND Laboratory.PLT < 400	thrombosis_prediction
SELECT AVG(T2.PT) FROM Patient AS T1 INNER JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE T1.SEX = 'M' AND T2.PT < 14	thrombosis_prediction
SELECT COUNT(T1.ID) FROM Examination AS T1 JOIN Laboratory AS T2 ON T1.ID = T2.ID WHERE (T1.Thrombosis = 1 OR T1.Thrombosis = 2) AND T2.PT < 14	thrombosis_prediction
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Angela' AND mem.last_name = 'Sanders'	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.college = 'College of Engineering'	student_club
SELECT m.first_name, m.last_name FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.department = 'Art and Design Department'	student_club
SELECT COUNT(T1.event_id) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Women''s Soccer'	student_club
SELECT m.phone FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE e.event_name = 'Women''s Soccer'	student_club
SELECT COUNT(e.event_id) FROM event e JOIN attendance a ON e.event_id = a.link_to_event JOIN member m ON a.link_to_member = m.member_id WHERE e.event_name = 'Women''s Soccer' AND m.t_shirt_size = 'Medium'	student_club
SELECT e.event_name FROM attendance a JOIN event e ON a.link_to_event = e.event_id GROUP BY a.link_to_event, e.event_name ORDER BY COUNT(a.link_to_member) DESC LIMIT 1	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'Vice President'	student_club
SELECT e.event_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.first_name = 'Maya' AND m.last_name = 'Mclean'	student_club
SELECT COUNT(T1.event_id) FROM event AS T1 JOIN attendance AS T2 ON T1.event_id = T2.link_to_event JOIN member AS T3 ON T2.link_to_member = T3.member_id WHERE T3.first_name = 'Sacha' AND T3.last_name = 'Harrison' AND STRFTIME('%Y', T1.event_date) = '2019'	student_club
SELECT e.event_name FROM event e JOIN ( SELECT link_to_event, COUNT(*) as attendee_count FROM attendance GROUP BY link_to_event HAVING COUNT(*) > 10 ) a ON e.event_id = a.link_to_event WHERE e.type != 'Meeting'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event WHERE e.type != 'Fundraiser' GROUP BY e.event_id, e.event_name HAVING COUNT(*) > 20	student_club
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
SELECT m.first_name, m.last_name FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE z.state = 'Illinois'	student_club
SELECT b.spent FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Advertisement' AND e.event_name = 'September Meeting'	student_club
SELECT DISTINCT m.department FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.last_name IN ('Pierce', 'Guidi')	student_club
SELECT SUM(T2.amount) FROM event AS T1 INNER JOIN budget AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'October Speaker'	student_club
SELECT e.approved FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id JOIN event ev ON b.link_to_event = ev.event_id WHERE ev.event_name = 'October Meeting' AND DATE(ev.event_date) = '2019-10-08'	student_club
SELECT AVG(T2.cost) FROM member AS T1 INNER JOIN expense AS T2 ON T1.member_id = T2.link_to_member WHERE T1.first_name = 'Elijah' AND T1.last_name = 'Allen' AND SUBSTR(T2.expense_date, 6, 2) IN ('09', '10')	student_club
SELECT (SELECT COALESCE(SUM(b.spent), 0) FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE SUBSTR(e.event_date, 1, 4) = '2019') - (SELECT COALESCE(SUM(b.spent), 0) FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE SUBSTR(e.event_date, 1, 4) = '2020') AS num	student_club
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
SELECT m.first_name, m.last_name FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE i.source = 'Dues' ORDER BY CAST(i.date_received AS INTEGER) LIMIT 1	student_club
SELECT CAST(SUM(CASE WHEN T2.event_name = 'Yearly Kickoff' THEN T1.amount ELSE 0 END) AS REAL) / SUM(CASE WHEN T2.event_name = 'October Meeting' THEN T1.amount ELSE 0 END) FROM budget T1 JOIN event T2 ON T1.link_to_event = T2.event_id WHERE T1.category = 'Advertisement'	student_club
SELECT CAST(SUM(CASE WHEN T1.category = 'Parking' THEN T1.amount ELSE 0 END) AS REAL) * 100 / SUM(T1.amount) FROM budget AS T1 JOIN event AS T2 ON T1.link_to_event = T2.event_id WHERE T2.event_name = 'November Speaker'	student_club
SELECT SUM(cost) FROM expense WHERE expense_description = 'Pizza'	student_club
SELECT COUNT(DISTINCT city) FROM zip_code WHERE county = 'Orange County' AND state = 'Virginia'	student_club
SELECT DISTINCT department FROM major WHERE college = 'College of Humanities and Social Sciences'	student_club
SELECT z.city, z.county, z.state FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Amy' AND m.last_name = 'Firth'	student_club
SELECT e.expense_description FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id ORDER BY b.remaining ASC LIMIT (SELECT COUNT(*) FROM expense WHERE link_to_budget = ( SELECT budget_id FROM budget ORDER BY remaining ASC LIMIT 1 ))	student_club
SELECT a.link_to_member AS member_id FROM attendance a JOIN event e ON a.link_to_event = e.event_id WHERE e.event_name = 'October Meeting'	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id GROUP BY m.college ORDER BY COUNT(*) DESC LIMIT 1	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.phone = '809-555-3360'	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event ORDER BY b.amount DESC LIMIT 1	student_club
SELECT e.expense_id, e.expense_description FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE m.position = 'Vice President'	student_club
SELECT COUNT(T2.link_to_member) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Women''s Soccer'	student_club
SELECT i.date_received FROM income i JOIN member m ON m.member_id = i.link_to_member WHERE m.first_name = 'Casey' AND m.last_name = 'Mason'	student_club
SELECT COUNT(T2.member_id) FROM zip_code AS T1 INNER JOIN member AS T2 ON T1.zip_code = T2.zip WHERE T1.state = 'Maryland'	student_club
SELECT COUNT(T2.link_to_event) FROM member AS T1 INNER JOIN attendance AS T2 ON T1.member_id = T2.link_to_member WHERE T1.phone = '954-555-6240'	student_club
SELECT member.first_name, member.last_name FROM member JOIN major ON member.link_to_major = major.major_id WHERE major.department = 'School of Applied Sciences, Technology and Education'	student_club
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
SELECT SUM(e.cost) FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id JOIN event ev ON b.link_to_event = ev.event_id WHERE ev.event_name = 'Yearly Kickoff'	student_club
SELECT DISTINCT m.first_name, m.last_name FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense exp ON b.budget_id = exp.link_to_budget JOIN member m ON exp.link_to_member = m.member_id WHERE e.event_name = 'Yearly Kickoff'	student_club
SELECT m.first_name, m.last_name, i.source FROM member m JOIN income i ON m.member_id = i.link_to_member ORDER BY i.amount DESC LIMIT 1	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget ORDER BY ex.cost ASC LIMIT 1	student_club
SELECT CAST(SUM(CASE WHEN T1.event_name = 'Yearly Kickoff' THEN T3.cost ELSE 0 END) AS REAL) * 100 / SUM(T3.cost) FROM event AS T1 JOIN budget AS T2 ON T1.event_id = T2.link_to_event JOIN expense AS T3 ON T2.budget_id = T3.link_to_budget	student_club
SELECT CAST(SUM(major_name = 'Finance') AS REAL) / SUM(major_name = 'Physics') AS ratio FROM major	student_club
SELECT source FROM income WHERE date_received BETWEEN '2019-09-01' AND '2019-09-30' ORDER BY amount DESC LIMIT 1	student_club
SELECT first_name, last_name, email FROM member WHERE position = 'Secretary'	student_club
SELECT COUNT(T2.member_id) FROM major AS T1 INNER JOIN member AS T2 ON T1.major_id = T2.link_to_major WHERE T1.major_name = 'Physics Teaching'	student_club
SELECT COUNT(T2.link_to_member) FROM event AS T1 INNER JOIN attendance AS T2 ON T1.event_id = T2.link_to_event WHERE T1.event_name = 'Community Theater' AND STRFTIME('%Y', T1.event_date) = '2019'	student_club
SELECT COUNT(T3.link_to_event), T4.major_name FROM member AS T1 JOIN attendance AS T3 ON T1.member_id = T3.link_to_member JOIN major AS T4 ON T1.link_to_major = T4.major_id WHERE T1.first_name = 'Luisa' AND T1.last_name = 'Guidi'	student_club
SELECT SUM(spent) / COUNT(spent) FROM budget WHERE category = 'Food' AND event_status = 'Closed'	student_club
SELECT e.event_name FROM budget b JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Advertisement' ORDER BY b.spent DESC LIMIT 1	student_club
SELECT IIF(COUNT(*) > 0, 'YES', 'NO') AS result FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.first_name = 'Maya' AND m.last_name = 'Mclean' AND e.event_name = 'Women''s Soccer'	student_club
SELECT CAST(SUM(CASE WHEN type = 'Community Service' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(type) FROM event WHERE event_date BETWEEN '2019-01-01' AND '2019-12-31'	student_club
SELECT e.cost FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id JOIN event ev ON b.link_to_event = ev.event_id WHERE e.expense_description = 'Posters' AND ev.event_name = 'September Speaker'	student_club
SELECT t_shirt_size FROM member GROUP BY t_shirt_size ORDER BY COUNT(*) DESC LIMIT 1	student_club
SELECT e.event_name FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE e.status = 'Closed' AND b.remaining < 0 ORDER BY b.remaining ASC LIMIT 1	student_club
SELECT T2.category AS type, SUM(T3.cost) AS "SUM(T3.cost)" FROM event AS T1 JOIN budget AS T2 ON T1.event_id = T2.link_to_event JOIN expense AS T3 ON T2.budget_id = T3.link_to_budget WHERE T1.event_name = 'October Meeting' AND T3.approved = 'true' GROUP BY T2.category	student_club
SELECT T1.category, SUM(T1.amount) FROM budget AS T1 JOIN event AS T2 ON T1.link_to_event = T2.event_id WHERE T2.event_name = 'April Speaker' GROUP BY T1.category ORDER BY SUM(T1.amount) ASC	student_club
SELECT budget_id FROM budget WHERE category = 'Food' ORDER BY amount DESC LIMIT 1	student_club
SELECT budget_id FROM budget WHERE category = 'Advertisement' ORDER BY amount DESC LIMIT 3	student_club
SELECT SUM(cost) FROM expense WHERE expense_description = 'Parking'	student_club
SELECT SUM(cost) FROM expense WHERE expense_date = '2019-08-20'	student_club
SELECT m.first_name, m.last_name, SUM(e.cost) FROM member m JOIN expense e ON m.member_id = e.link_to_member WHERE m.member_id = 'rec4BLdZHS2Blfp4v' GROUP BY m.first_name, m.last_name	student_club
SELECT DISTINCT e.expense_description FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE m.first_name = 'Sacha' AND m.last_name = 'Harrison'	student_club
SELECT DISTINCT expense.expense_description FROM expense JOIN member ON expense.link_to_member = member.member_id WHERE member.t_shirt_size = 'X-Large'	student_club
SELECT DISTINCT m.zip FROM member m JOIN expense e ON m.member_id = e.link_to_member WHERE e.cost < 50	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Phillip' AND mem.last_name = 'Cullen'	student_club
SELECT m.position FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Business'	student_club
SELECT COUNT(T2.member_id) FROM major AS T1 JOIN member AS T2 ON T1.major_id = T2.link_to_major WHERE T1.major_name = 'Business' AND T2.t_shirt_size = 'Medium'	student_club
SELECT DISTINCT e.type FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.remaining > 30	student_club
SELECT type AS category FROM event WHERE location = 'MU 215'	student_club
SELECT type AS category FROM event WHERE event_date = '2020-03-24T12:00:00'	student_club
SELECT m.major_name FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.position = 'Vice President'	student_club
SELECT CAST(SUM(CASE WHEN T2.major_name = 'Business' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(T1.member_id) FROM member T1 JOIN major T2 ON T1.link_to_major = T2.major_id	student_club
SELECT DISTINCT type AS category FROM event WHERE location = 'MU 215'	student_club
SELECT COUNT(income_id) FROM income WHERE amount = 50	student_club
SELECT COUNT(member_id) FROM member WHERE position = 'Member' AND t_shirt_size = 'X-Large'	student_club
SELECT COUNT(major_id) FROM major WHERE college = 'College of Agriculture and Applied Sciences' AND department = 'School of Applied Sciences, Technology and Education'	student_club
SELECT m.last_name, maj.department, maj.college FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Environmental Engineering'	student_club
SELECT b.category, e.type FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE e.location = 'MU 215' AND e.type = 'Guest Speaker' AND b.spent = 0	student_club
SELECT z.city, z.state FROM member m JOIN major maj ON m.link_to_major = maj.major_id JOIN zip_code z ON m.zip = z.zip_code WHERE maj.department = 'Electrical and Computer Engineering Department' AND m.position = 'Member'	student_club
SELECT e.event_name FROM event e JOIN attendance a ON e.event_id = a.link_to_event JOIN member m ON a.link_to_member = m.member_id WHERE e.type = 'Social' AND m.position = 'Vice President' AND e.location = '900 E. Washington St.'	student_club
SELECT m.last_name, m.position FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.expense_description = 'Pizza' AND e.expense_date = '2019-09-10'	student_club
SELECT m.last_name FROM member m JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id WHERE m.position = 'Member' AND e.event_name = 'Women''s Soccer'	student_club
SELECT CAST(SUM(CASE WHEN T2.amount = 50 THEN 1.0 ELSE 0 END) AS REAL) * 100 / COUNT(T2.income_id) FROM member AS T1 INNER JOIN income AS T2 ON T1.member_id = T2.link_to_member WHERE T1.t_shirt_size = 'Medium' AND T1.position = 'Member'	student_club
SELECT DISTINCT county FROM zip_code WHERE type = 'PO Box'	student_club
SELECT zip_code FROM zip_code WHERE type = 'PO Box' AND county = 'San Juan Municipio' AND state = 'Puerto Rico'	student_club
SELECT event_name FROM event WHERE type = 'Game' AND status = 'Closed' AND event_date BETWEEN '2019-03-15' AND '2020-03-20'	student_club
SELECT DISTINCT a.link_to_event FROM expense e JOIN attendance a ON e.link_to_member = a.link_to_member WHERE e.cost > 50	student_club
SELECT e.link_to_member, a.link_to_event FROM expense e JOIN attendance a ON e.link_to_member = a.link_to_member WHERE e.approved = 'true' AND e.expense_date BETWEEN '2019-01-10' AND '2019-11-19'	student_club
SELECT m.college FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Katy' AND mem.link_to_major = 'rec1N0upiVLy5esTO'	student_club
SELECT member.phone FROM member JOIN major ON member.link_to_major = major.major_id WHERE major.major_name = 'Business' AND major.college = 'College of Agriculture and Applied Sciences'	student_club
SELECT DISTINCT m.email FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.cost > 20 AND e.expense_date BETWEEN '2019-09-10' AND '2019-11-19'	student_club
SELECT COUNT(T1.member_id) FROM member AS T1 JOIN major AS T2 ON T1.link_to_major = T2.major_id WHERE T2.major_name = 'education' AND T2.college = 'College of Education & Human Services'	student_club
SELECT CAST(SUM(CASE WHEN remaining < 0 THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(budget_id) FROM budget	student_club
SELECT event_id, location, status FROM event WHERE event_date BETWEEN '2019-11-01' AND '2020-03-31'	student_club
SELECT expense_description FROM expense GROUP BY expense_description HAVING AVG(cost) > 50	student_club
SELECT first_name, last_name FROM member WHERE t_shirt_size = 'X-Large'	student_club
SELECT CAST(SUM(CASE WHEN type = 'PO Box' THEN 1 ELSE 0 END) AS REAL) * 100 / COUNT(zip_code) FROM zip_code	student_club
SELECT DISTINCT e.event_name, e.location FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE b.remaining > 0	student_club
SELECT e.event_name, e.event_date FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget WHERE ex.expense_description = 'Pizza' AND ex.cost > 50 AND ex.cost < 100	student_club
SELECT DISTINCT m.first_name, m.last_name, maj.major_name FROM member m JOIN expense e ON m.member_id = e.link_to_member JOIN major maj ON m.link_to_major = maj.major_id WHERE e.cost > 100	student_club
SELECT z.city, z.county FROM income i JOIN member m ON i.link_to_member = m.member_id JOIN zip_code z ON m.zip = z.zip_code JOIN attendance a ON m.member_id = a.link_to_member JOIN event e ON a.link_to_event = e.event_id GROUP BY e.event_id HAVING COUNT(i.income_id) > 40	student_club
SELECT e.link_to_member AS member_id FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id GROUP BY e.link_to_member HAVING COUNT(DISTINCT b.link_to_event) > 1 ORDER BY SUM(e.cost) DESC LIMIT 1	student_club
SELECT AVG(e.cost) FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE m.position != 'Member'	student_club
SELECT e.event_name FROM expense ex JOIN budget b ON ex.link_to_budget = b.budget_id JOIN event e ON b.link_to_event = e.event_id WHERE b.category = 'Parking' AND ex.cost < ( SELECT AVG(ex2.cost) FROM expense ex2 JOIN budget b2 ON ex2.link_to_budget = b2.budget_id WHERE b2.category = 'Parking' )	student_club
SELECT SUM(CASE WHEN e.type = 'Meeting' THEN ex.cost ELSE 0 END) * 100.0 / SUM(ex.cost) AS "SUM(CASE WHEN T1.type = 'Meeting' THEN T3.cost ELSE 0 END) * 100 / SUM(T3.cost)" FROM event e JOIN budget b ON e.event_id = b.link_to_event JOIN expense ex ON b.budget_id = ex.link_to_budget	student_club
SELECT e.link_to_budget AS budget_id FROM expense e WHERE e.expense_description = 'Water, chips, cookies' ORDER BY e.cost DESC LIMIT 1	student_club
SELECT m.first_name, m.last_name FROM member m JOIN expense e ON m.member_id = e.link_to_member GROUP BY m.member_id, m.first_name, m.last_name ORDER BY SUM(e.cost) DESC LIMIT 5	student_club
SELECT DISTINCT m.first_name, m.last_name, m.phone FROM member m JOIN expense e ON m.member_id = e.link_to_member WHERE e.cost > (SELECT AVG(cost) FROM expense)	student_club
SELECT CAST(SUM(CASE WHEN z.state = 'New Jersey' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN m.position = 'Member' THEN 1 ELSE 0 END) - CAST(SUM(CASE WHEN z.state = 'Vermont' THEN 1 ELSE 0 END) AS REAL) * 100 / SUM(CASE WHEN m.position = 'Member' THEN 1 ELSE 0 END) AS diff FROM member m JOIN zip_code z ON m.zip = z.zip_code	student_club
SELECT m.major_name, m.department FROM member mem JOIN major m ON mem.link_to_major = m.major_id WHERE mem.first_name = 'Garrett' AND mem.last_name = 'Gerke'	student_club
SELECT m.first_name, m.last_name, e.cost FROM expense e JOIN member m ON e.link_to_member = m.member_id WHERE e.expense_description = 'Water, Veggie tray, supplies'	student_club
SELECT m.last_name, m.phone FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE maj.major_name = 'Elementary Education'	student_club
SELECT b.category, b.amount FROM event e JOIN budget b ON e.event_id = b.link_to_event WHERE e.event_name = 'January Speaker'	student_club
SELECT event.event_name FROM event JOIN budget ON event.event_id = budget.link_to_event WHERE budget.category = 'Food'	student_club
SELECT m.first_name, m.last_name, i.amount FROM income i JOIN member m ON i.link_to_member = m.member_id WHERE i.date_received = '2019-09-09'	student_club
SELECT DISTINCT b.category FROM expense e JOIN budget b ON e.link_to_budget = b.budget_id WHERE e.expense_description = 'Posters'	student_club
SELECT m.first_name, m.last_name, maj.college FROM member m JOIN major maj ON m.link_to_major = maj.major_id WHERE m.position = 'Secretary'	student_club
SELECT SUM(budget.spent), event.event_name FROM budget JOIN event ON budget.link_to_event = event.event_id WHERE budget.category = 'Speaker Gifts' GROUP BY event.event_name	student_club
SELECT z.city FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE m.first_name = 'Garrett' AND m.last_name = 'Gerke'	student_club
SELECT m.first_name, m.last_name, m.position FROM member m JOIN zip_code z ON m.zip = z.zip_code WHERE z.city = 'Lincolnton' AND z.state = 'North Carolina' AND z.zip_code = 28092	student_club
SELECT COUNT(GasStationID) FROM gasstations WHERE Country = 'CZE' AND Segment = 'Premium'	debit_card_specializing
SELECT CAST(SUM(CASE WHEN Currency = 'EUR' THEN 1 ELSE 0 END) AS REAL) / SUM(CASE WHEN Currency = 'CZK' THEN 1 ELSE 0 END) AS ratio FROM customers	debit_card_specializing
SELECT y.CustomerID FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE CAST(y.Date AS INTEGER) BETWEEN 201201 AND 201212 AND c.Segment = 'LAM' ORDER BY y.Consumption ASC LIMIT 1	debit_card_specializing
SELECT AVG(T2.Consumption) / 12 FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'SME' AND CAST(T2.Date AS INTEGER) BETWEEN 201301 AND 201312	debit_card_specializing
SELECT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Currency = 'CZK' AND CAST(y.Date AS INTEGER) BETWEEN 201101 AND 201112 GROUP BY c.CustomerID ORDER BY SUM(y.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT COUNT(*) FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'KAM' AND CAST(y.Date AS INTEGER) BETWEEN 201201 AND 201212 AND y.Consumption < 30000	debit_card_specializing
SELECT SUM(IIF(c.Currency = 'CZK', y.Consumption, 0)) - SUM(IIF(c.Currency = 'EUR', y.Consumption, 0)) AS "SUM(IIF(T1.Currency = 'CZK', T2.Consumption, 0)) - SUM(IIF(T1.Currency = 'EUR', T2.Consumption, 0))" FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE CAST(y.Date AS INTEGER) BETWEEN 201201 AND 201212	debit_card_specializing
SELECT SUBSTRING(T2.Date, 1, 4) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Currency = 'EUR' GROUP BY SUBSTRING(T2.Date, 1, 4) ORDER BY SUM(T2.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT c.Segment FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID GROUP BY c.Segment ORDER BY SUM(y.Consumption) ASC LIMIT 1	debit_card_specializing
SELECT SUBSTR(T1.Date, 1, 4) FROM yearmonth AS T1 JOIN customers AS T2 ON T1.CustomerID = T2.CustomerID WHERE T2.Currency = 'CZK' GROUP BY SUBSTR(T1.Date, 1, 4) ORDER BY SUM(T1.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT SUBSTR(T2.Date, 5, 2) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'SME' AND SUBSTR(T2.Date, 1, 4) = '2013' ORDER BY T2.Consumption DESC LIMIT 1	debit_card_specializing
SELECT CAST(SUM(IIF(T1.Segment = 'SME', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'LAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID), CAST(SUM(IIF(T1.Segment = 'LAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'KAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID), CAST(SUM(IIF(T1.Segment = 'KAM', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) - CAST(SUM(IIF(T1.Segment = 'SME', T2.Consumption, 0)) AS REAL) / COUNT(T1.CustomerID) FROM customers T1 JOIN yearmonth T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Currency = 'CZK' AND CAST(T2.Date AS INTEGER) BETWEEN 201301 AND 201312	debit_card_specializing
SELECT CAST((SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2012%', T2.Consumption, 0))) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'SME' AND T2.Date LIKE '2012%', T2.Consumption, 0)), CAST(SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'LAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)), CAST(SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2013%', T2.Consumption, 0)) - SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) AS FLOAT) * 100 / SUM(IIF(T1.Segment = 'KAM' AND T2.Date LIKE '2012%', T2.Consumption, 0)) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID	debit_card_specializing
SELECT SUM(Consumption) FROM yearmonth WHERE CustomerID = 6 AND Date BETWEEN '201308' AND '201311'	debit_card_specializing
SELECT SUM(IIF(Country = 'CZE', 1, 0)) - SUM(IIF(Country = 'SVK', 1, 0)) FROM gasstations WHERE Segment = 'Discount'	debit_card_specializing
SELECT SUM(IIF(CustomerID = 7, Consumption, 0)) - SUM(IIF(CustomerID = 5, Consumption, 0)) FROM yearmonth WHERE CAST("Date" AS INTEGER) = 201304	debit_card_specializing
SELECT SUM(Currency = 'CZK') - SUM(Currency = 'EUR') FROM customers WHERE Segment = 'SME'	debit_card_specializing
SELECT c.CustomerID FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'LAM' AND c.Currency = 'EUR' AND CAST(y.Date AS INTEGER) = 201310 ORDER BY y.Consumption DESC LIMIT 1	debit_card_specializing
SELECT c.CustomerID, SUM(y.Consumption) FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Segment = 'KAM' GROUP BY c.CustomerID ORDER BY SUM(y.Consumption) DESC LIMIT 1	debit_card_specializing
SELECT SUM(T2.Consumption) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'KAM' AND CAST(T2.Date AS INTEGER) = 201305	debit_card_specializing
SELECT CAST(SUM(IIF(T2.Consumption > 46.73, 1, 0)) AS FLOAT) * 100 / COUNT(T1.CustomerID) FROM customers AS T1 INNER JOIN yearmonth AS T2 ON T1.CustomerID = T2.CustomerID WHERE T1.Segment = 'LAM'	debit_card_specializing
SELECT Country, (SELECT COUNT(GasStationID) FROM gasstations WHERE Segment = 'Value for money') FROM gasstations WHERE Segment = 'Value for money' GROUP BY Country	debit_card_specializing
SELECT CAST(SUM(Currency = 'EUR') AS FLOAT) * 100 / COUNT(CustomerID) FROM customers WHERE Segment = 'KAM'	debit_card_specializing
SELECT CAST(SUM(IIF(Consumption > 528.3, 1, 0)) AS FLOAT) * 100 / COUNT(CustomerID) FROM yearmonth WHERE Date = '201202'	debit_card_specializing
SELECT CAST(SUM(IIF(Segment = 'Premium', 1, 0)) AS FLOAT) * 100 / COUNT(GasStationID) FROM gasstations WHERE Country = 'SVK'	debit_card_specializing
SELECT CustomerID FROM yearmonth WHERE Date = '201309' ORDER BY Consumption DESC LIMIT 1	debit_card_specializing
SELECT c.Segment FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE y.Date = '201309' GROUP BY c.Segment ORDER BY SUM(y.Consumption) ASC LIMIT 1	debit_card_specializing
SELECT y.CustomerID FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE c.Segment = 'SME' AND y.Date = '201206' ORDER BY y.Consumption ASC LIMIT 1	debit_card_specializing
SELECT MAX(monthly_sum) AS "SUM(Consumption)" FROM (SELECT SUM(Consumption) AS monthly_sum FROM yearmonth WHERE SUBSTR(CAST("Date" AS TEXT), 1, 4) = '2012' GROUP BY SUBSTR(CAST("Date" AS TEXT), 5, 2))	debit_card_specializing
SELECT SUM(y.Consumption) / 12 AS MonthlyConsumption FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT TRIM(p.Description) AS Description FROM transactions_1k t JOIN products p ON t.ProductID = p.ProductID WHERE STRFTIME('%Y%m', t.Date) = '201309'	debit_card_specializing
SELECT DISTINCT g.Country FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID JOIN transactions_1k t ON c.CustomerID = t.CustomerID JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE y.Date = '201306'	debit_card_specializing
SELECT DISTINCT g.ChainID FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT DISTINCT p.ProductID, TRIM(p.Description) AS Description FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID JOIN products p ON t.ProductID = p.ProductID WHERE c.Currency = 'EUR'	debit_card_specializing
SELECT AVG(Amount) FROM transactions_1k WHERE Date LIKE '%2012-01%'	debit_card_specializing
SELECT COUNT(*) FROM customers c JOIN yearmonth y ON c.CustomerID = y.CustomerID WHERE c.Currency = 'EUR' AND y.Consumption > 1000	debit_card_specializing
SELECT TRIM(p.Description) AS Description FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID JOIN products p ON t.ProductID = p.ProductID WHERE g.Country = 'CZE'	debit_card_specializing
SELECT DISTINCT t.Time FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE g.ChainID = 11	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k AS T1 INNER JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE' AND T1.Price > 1000	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k AS T1 INNER JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE' AND T1.Date > '2012-01-01'	debit_card_specializing
SELECT AVG(T1.Price) FROM transactions_1k AS T1 INNER JOIN gasstations AS T2 ON T1.GasStationID = T2.GasStationID WHERE T2.Country = 'CZE'	debit_card_specializing
SELECT AVG(T1.Price) FROM transactions_1k AS T1 JOIN customers AS C ON T1.CustomerID = C.CustomerID WHERE C.Currency = 'EUR'	debit_card_specializing
SELECT CustomerID FROM transactions_1k WHERE Date = '2012-08-25' ORDER BY Price DESC LIMIT 1	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.Date = '2012-08-25' ORDER BY CAST(t.Time AS INTEGER) LIMIT 1	debit_card_specializing
SELECT DISTINCT c.Currency FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Date = '2012-08-24' AND t.Time = '16:25:00'	debit_card_specializing
SELECT c.Segment FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Date = '2012-08-23' AND t.Time = '21:20:00'	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k T1 JOIN customers C ON T1.CustomerID = C.CustomerID WHERE T1.Date = '2012-08-26' AND CAST(T1.Time AS INTEGER) < 130000 AND C.Currency = 'CZK'	debit_card_specializing
SELECT c.Segment FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID ORDER BY t.Date ASC LIMIT 1	debit_card_specializing
SELECT DISTINCT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.Date = '2012-08-24' AND t.Time = '12:42:00'	debit_card_specializing
SELECT ProductID FROM transactions_1k WHERE Date = '2012-08-23' AND Time = '21:20:00'	debit_card_specializing
SELECT t.CustomerID, y.Date, y.Consumption FROM (SELECT CustomerID FROM transactions_1k WHERE Date = '2012-08-24' AND Price = 124.05) t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE y.Date = '201201' ORDER BY t.CustomerID	debit_card_specializing
SELECT COUNT(T1.TransactionID) FROM transactions_1k T1 JOIN gasstations T2 ON T1.GasStationID = T2.GasStationID WHERE T1.Date = '2012-08-26' AND T1.Time BETWEEN '08:00:00' AND '09:00:00' AND T2.Country = 'CZE'	debit_card_specializing
SELECT c.Currency FROM yearmonth y JOIN customers c ON y.CustomerID = c.CustomerID WHERE y.Date = '201306' AND y.Consumption = 214582.17	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.CardID = 667467	debit_card_specializing
SELECT c.Currency AS Country FROM transactions_1k t JOIN customers c ON t.CustomerID = c.CustomerID WHERE t.Date = '2012-08-24' AND t.Price = 548.4	debit_card_specializing
SELECT CAST(SUM(IIF(T2.Currency = 'EUR', 1, 0)) AS FLOAT) * 100 / COUNT(T1.CustomerID) FROM transactions_1k AS T1 JOIN customers AS T2 ON T1.CustomerID = T2.CustomerID WHERE date(T1.Date) = '2012-08-25'	debit_card_specializing
SELECT CAST(SUM(IIF(SUBSTR(y.Date, 1, 4) = '2012', y.Consumption, 0)) - SUM(IIF(SUBSTR(y.Date, 1, 4) = '2013', y.Consumption, 0)) AS FLOAT) / SUM(IIF(SUBSTR(y.Date, 1, 4) = '2012', y.Consumption, 0)) FROM transactions_1k t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE t.Price = 634.8 AND date(t.Date) = '2012-08-25'	debit_card_specializing
SELECT GasStationID FROM transactions_1k GROUP BY GasStationID ORDER BY SUM(Price * Amount) DESC LIMIT 1	debit_card_specializing
SELECT (CAST(SUM(IIF(Country = 'SVK' AND Segment = 'Premium', 1, 0)) AS FLOAT) * 100 / SUM(IIF(Country = 'SVK', 1, 0))) FROM gasstations	debit_card_specializing
SELECT SUM(T1.Price), SUM(IIF(T3.Date = '201201', T1.Price, 0)) FROM transactions_1k AS T1 JOIN yearmonth AS T3 ON T1.CustomerID = T3.CustomerID AND strftime('%Y%m', T1.Date) = T3.Date WHERE T1.CustomerID = 38508	debit_card_specializing
SELECT TRIM(p.Description) AS Description FROM transactions_1k t JOIN products p ON t.ProductID = p.ProductID GROUP BY p.ProductID, p.Description ORDER BY SUM(t.Amount) DESC LIMIT 5	debit_card_specializing
SELECT c.CustomerID, SUM(t.Price / t.Amount) AS avg_price_per_item_sum, c.Currency FROM customers c JOIN transactions_1k t ON c.CustomerID = t.CustomerID WHERE t.Amount > 0 GROUP BY c.CustomerID, c.Currency ORDER BY SUM(t.Price) DESC LIMIT 1	debit_card_specializing
SELECT g.Country FROM transactions_1k t JOIN gasstations g ON t.GasStationID = g.GasStationID WHERE t.ProductID = 2 ORDER BY t.Price DESC LIMIT 1	debit_card_specializing
SELECT y.Consumption FROM transactions_1k t JOIN yearmonth y ON t.CustomerID = y.CustomerID WHERE t.ProductID = 5 AND (t.Price / t.Amount) > 29.00 AND y.Date = '201208'	debit_card_specializing
