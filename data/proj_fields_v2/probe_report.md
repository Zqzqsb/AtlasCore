# Projection-field wash probe (v2, schema=gold_fk)

## Counts

### train

```
ok: 7619
schema_gold_fk: 7619
kind_col: 7149
nfields_1: 6293
shape_list: 3542
shape_scalar: 2825
nl_count_and_gold_scalar: 1933
excluded_heldout: 1809
kind_count: 1620
shape_entity: 1121
nfields_2: 970
kind_sum: 376
nfields_3: 269
nl_count_but_gold_list: 236
kind_avg: 198
shape_table: 131
nfields_4: 66
kind_max: 42
kind_min: 29
nfields_5: 16
kind_star: 4
nfields_6: 3
name_has_parens: 2
nfields_7: 1
nfields_9: 1
```

### dev

```
ok: 1534
schema_gold_fk: 1534
kind_col: 1512
nfields_1: 1255
shape_list: 771
shape_scalar: 527
nl_count_and_gold_scalar: 334
kind_count: 304
shape_entity: 209
nfields_2: 198
nfields_3: 68
kind_sum: 44
kind_avg: 40
nl_count_but_gold_list: 39
shape_table: 27
name_has_parens: 11
nfields_4: 11
kind_max: 7
kind_min: 3
nfields_5: 1
nfields_6: 1
```

## v2 label design

| shape | Meaning |
|-------|--------|
| scalar | Aggregates without GROUP BY |
| list | Multi-row projection |
| entity | Non-agg with LIMIT 1 |
| table | Agg + GROUP BY |

**field.name (v2):** short label — alias or bare column; aggregates use column name + kind (COUNT(*) → name `"*"`).
**schema (v2 default):** gold SQL tables + one FK hop (not full DB).

## Gold-quirk samples (NL count → gold list)

- **movie_platform**: List all movies with the best rating score. State the movie title and number of Mubi user who loves 
  - target: `{"shape":"list","fields":[{"name":"movie_title","kind":"col"},{"name":"movie_popularity","kind":"col"}]}`
  - sql: `SELECT DISTINCT T2.movie_title, T2.movie_popularity FROM ratings AS T1 INNER JOIN movies AS T2 ON T1.movie_id = T2.movie_id WHERE T1.rating_`
- **movie_platform**: Was the user who created the "World War 2 and Kids" list eligible for trial when he created the list
  - target: `{"shape":"list","fields":[{"name":"user_eligible_for_trial","kind":"col"},{"name":"list_followers","kind":"col"}]}`
  - sql: `SELECT T2.user_eligible_for_trial, T1.list_followers FROM lists AS T1 INNER JOIN lists_users AS T2 ON T1.user_id = T1.user_id AND T1.list_id`
- **movie_platform**: Which year has the least number of movies that was released and what is the title of the movie in th
  - target: `{"shape":"list","fields":[{"name":"movie_release_year","kind":"col"},{"name":"movie_title","kind":"col"}]}`
  - sql: `SELECT DISTINCT T1.movie_release_year, T1.movie_title FROM movies AS T1 INNER JOIN ratings AS T2 ON T1.movie_id = T2.movie_id WHERE T1.movie`
- **movie_platform**: How many users who created a list in the February of 2016 were eligible for trial when they created 
  - target: `{"shape":"list","fields":[{"name":"list_followers","kind":"col"}]}`
  - sql: `SELECT T1.list_followers FROM lists AS T1 INNER JOIN lists_users AS T2 ON T1.user_id = T2.user_id AND T1.list_id = T2.list_id WHERE T2.list_`
- **movie_platform**: How many directors have directed atleast 10 movies between 1960 to 1985? Indicate the name of the mo
  - target: `{"shape":"list","fields":[{"name":"director_name","kind":"col"}]}`
  - sql: `SELECT T2.director_name FROM ratings AS T1 INNER JOIN movies AS T2 ON T1.movie_id = T2.movie_id WHERE T2.movie_release_year BETWEEN 1960 AND`
- **movie_platform**: How many likes did the critic of the movie "Apocalypse Now" received after giving the movie a rating
  - target: `{"shape":"list","fields":[{"name":"critic_likes","kind":"col"}]}`
  - sql: `SELECT T2.critic_likes FROM movies AS T1 INNER JOIN ratings AS T2 ON T1.movie_id = T2.movie_id WHERE T2.user_trialist = 0 AND T2.rating_scor`
- **movie_platform**: Please list the names of the top three movies in the number of likes related to the critic made by t
  - target: `{"shape":"list","fields":[{"name":"movie_title","kind":"col"}]}`
  - sql: `SELECT T2.movie_title FROM ratings AS T1 INNER JOIN movies AS T2 ON T1.movie_id = T2.movie_id ORDER BY T1.critic_likes DESC LIMIT 3`
- **movie_platform**: For the user who post the list that contained the most number of the movies, is he/she a paying subs
  - target: `{"shape":"list","fields":[{"name":"user_has_payment_method","kind":"col"}]}`
  - sql: `SELECT T1.user_has_payment_method FROM lists_users AS T1 INNER JOIN lists AS T2 ON T1.list_id = T2.list_id WHERE T2.list_movie_number = ( SE`
