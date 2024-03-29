Эта база данных предназначена для управления информационными потоками в судебной системе.

Она позволяет отслеживать информацию о делах, участниках дел, судах, документах, слушаниях, судьях и судебных районах. 
Также она содержит данные о персонах и их ролях в судебных делах. 
Функции базы данных обеспечивают добавление, валидацию и обновление данных в соответствии с бизнес-правилами.


**Таблицы и их связи**


**1. Таблица persons**
Назначение: Хранит информацию о физических и юридических лицах.
Связи:
Связана с таблицей caseparticipants через personid, указывающий на участие персоны в конкретных делах.
Основные поля:
personid: целочисленный идентификатор, NOT NULL
fullname: строка переменной длины (до 255 символов), NOT NULL
dateofbirth: дата рождения
type: строка переменной длины (до 50 символов), NOT NULL
contactinfo: текст контактной информации


**2. Таблица cases**
Назначение: Содержит информацию о юридических делах.
Связи:
Связана с caseparticipants через caseid для отслеживания всех участников дела.
Связана с documents и hearings, где каждое дело может иметь несколько документов и слушаний.
Основные поля:
caseid: целочисленный идентификатор, NOT NULL
casename: строка переменной длины (до 255 символов), NOT NULL
description: текстовое описание
startdate: дата начала
enddate: дата окончания


**3. Таблица caseparticipants**
Назначение: Устанавливает связь между делами и участниками, указывая их роли.
Связи:
Связана с persons и cases для определения участия в делах.
Может быть связана с roles через roleid, если роли определены для участников.
Основные поля:
participationid: целочисленный идентификатор, NOT NULL
caseid: целочисленный идентификатор дела, NOT NULL
personid: целочисленный идентификатор персоны, NOT NULL
roleid: целочисленный идентификатор роли, NOT NULL


**4. Таблица roles**
Назначение: Определяет роли, которые могут быть присвоены участникам дел.
Связи:
Связана с caseparticipants через roleid для определения роли участников в делах.
Основные поля:
roleid: целочисленный идентификатор, NOT NULL
rolename: строка переменной длины (до 255 символов), NOT NULL


**5. Таблица courts**
Назначение: Содержит информацию о судах.
Связи:
Связана с judges через courtid для определения судей, работающих в каждом суде.
Связана с judicialdistricts через districtid для указания района расположения суда.
Основные поля:
courtid: целочисленный идентификатор, NOT NULL
courtname: строка переменной длины (до 255 символов), NOT NULL
districtid: целочисленный идентификатор района, NOT NULL


**6. Таблица judges**
Назначение: Хранит данные о судьях.
Связи:
Связана с courts через courtid, показывая, в каком суде работает судья.
Основные поля: 
judgeid: целочисленный идентификатор, NOT NULL
courtid: целочисленный идентификатор суда, NOT NULL


**7. Таблица judicialdistricts**
Назначение: Перечисляет судебные районы.
Связи:
Связана с courts через districtid, указывая, в каком районе находится суд.
Основные поля: 
districtid: целочисленный идентификатор, NOT NULL
districtname: строка переменной длины (до 255 символов), NOT NULL


**8. Таблица documents**
Назначение: Включает документы, связанные с юридическими делами.
Связи:
Связана с cases через caseid, позволяя отслеживать документы для каждого дела.
Основные поля: 
documentid: целочисленный идентификатор, NOT NULL
caseid: целочисленный идентификатор дела, NOT NULL
documentname: строка переменной длины (до 255 символов), NOT NULL
documenttype: строка переменной длины (до 50 символов)
creationdate: дата создания


**9. Таблица hearings**
Назначение: Записывает информацию о слушаниях в судебных делах.
Связана с cases через caseid
Основные поля:
hearingid: целочисленный идентификатор, NOT NULL
caseid: целочисленный идентификатор дела, NOT NULL
datetime: метка времени без временной зоны, NOT NULL
location: строка переменной длины (до 255 символов)
decision: текст решения


**Для работы с базой данных предусмотрено несколько функций.** Ниже описаны функции доступные для выбора и использования.

1. Функция для вывода списка дел, в которых участвует определённое лицо: get_cases_by_person(person_name VARCHAR)
2. Функция для вывода списка дел, над которыми работает конкретный судья: get_cases_by_judge(judge_name VARCHAR)
3. Функция для вычисления среднего времени рассмотрения дел для каждого судьи: get_average_case_duration()
4. Функция для составления рейтинга судей по количеству удовлетворенных дел: get_judges_success_rate()
5. Функция для вывода списка судей, рассмотревших более определённого количества дел за последний год: get_judges_by_case_count(last_year_count INT)
6. Функция для вывода списка юридических лиц, выигравших большинство своих дел по определённой категории: get_legal_entities_winning_majority(category VARCHAR)
7. Функция, которая определит категории дел, по которым чаще всего принимаются отрицательные решения: get_negative_decision_categories()
8. Функция, которая выводит список физических лиц, выигравших все свои дела, и судей, рассмотревших эти дела: get_persons_and_judges_with_all_wins()
9. Функция, которая позволяет отслеживать динамику количества дел по категориям за разные периоды: get_case_category_counts_by_period(IN start_date DATE, IN end_date DATE)
10. Функция, которая определяет судебные округи с наиболее эффективными показателями рассмотрения дел по сравнению с аналогичными делами в других округах: get_efficient_judicial_districts()

