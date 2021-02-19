import calendar
import os
import random
import string
import sys
from datetime import date, timedelta, datetime
from decimal import *
from re import sub

import numpy as np
import pandas as pd
from dateutil import relativedelta
from robot.libraries.BuiltIn import BuiltIn
from selenium import webdriver
from tika import parser
import time


def set_chrome_options():
    chromeOptions = webdriver.ChromeOptions()
    # Prefs to disable password/credentials saving alert (for Appian login)
    prefs = {"credentials_enable_service": False,
             'profile': {'password_manager_enabled': False}}
    chromeOptions.add_experimental_option("prefs", prefs)
    chromeOptions.add_argument("--no-sandbox")
    chromeOptions.add_argument("--headless")
    chromeOptions.add_argument("--disable-dev-shm-usage")
    chromeOptions.add_argument("--start-maximized")
    chromeOptions.add_argument("--window-size=1280,1080")
    # Disable all extensions before running
    chromeOptions.add_argument("--disable-extensions")
    # Ignore certificate errors (Appian side self-signed)
    chromeOptions.add_argument("--ignore-certificate-errors")
    # Disable insecure content error
    chromeOptions.add_argument("--allow-running-insecure-content")
    # Add additional switches/arguments below where necessary
    # reference: http://peter.sh/experiments/chromium-command-line-switches
    return chromeOptions


def generate_random_integer_in_range(min=1, max=sys.maxsize):
    min = int(min)
    max = int(max)
    integer = random.randint(min, max)
    integer = str(integer)
    return integer


def generate_random_float_with_custom_decimal(min=1, max=10000, roundTo=2):
    min = float(min)
    max = float(max)
    roundTo = int(roundTo)
    output = round(random.uniform(min, max), roundTo)
    output = str('{:.{}f}'.format(output, roundTo))
    return output


def get_random_item_from_list(input_list):
    """
    Returns a random item from 'input_list'
    """
    choice = random.choice(input_list)
    return choice


def get_random_items_from_list(input_list, num_of_items):
    """
    Returns a random items based on num_of_items from 'input_list'
    """
    rand_items = random.sample(input_list, int(num_of_items))
    return rand_items


def get_random_true_or_false_value():
    choice = random.choice(['true', 'false'])
    return choice


def get_random_yes_or_no_value():
    choice = random.choice(['Yes', 'No'])
    return choice


def generate_random_alphanumeric_string(length):
    """
    Returns a random alphanumeric string of length 'length'
    """
    key = ''
    for i in range(int(length)):
        key += random.choice(string.ascii_letters + string.digits)
    return key


def custom_country_list():
    country_list = ['Austria', 'Brazil', 'Canada', 'Egypt', 'Finland', 'Haiti', 'Iceland', 'Japan', 'Jamaica',
                    'Kuwait', 'Latvia', 'Maldives', 'New Zealand', 'Nepal', 'Oman', 'Poland', 'Qatar', 'Romania',
                    'Singapore', 'Thailand', 'Togo', 'United States', 'Vietnam', 'Yemen', 'Zambia']
    return country_list


def custom_country_code_dict():
    country_code_dict = {'Austria': 'AT', 'Brazil': 'BR', 'Canada': 'CA', 'Egypt': 'EG', 'Finland': 'FI', 'Haiti': 'HT',
                         'Iceland': 'IS', 'Japan': 'JP', 'Jamaica': 'JM', 'Kuwait': 'KW', 'Latvia': 'LV',
                         'Maldives': 'MV', 'New Zealand': 'NZ', 'Nepal': 'NP', 'Oman': 'OM', 'Poland': 'PL',
                         'Qatar': 'QA', 'Romania': 'RO', 'Singapore': 'SG', 'Thailand': 'TH', 'Togo': 'TG',
                         'United States': 'US', 'Vietnam': 'VN', 'Yemen': 'YE', 'Zambia': 'ZM'}
    return country_code_dict


def get_random_country():
    country_list = custom_country_list()
    return get_random_item_from_list(country_list)


def get_random_countries(numItems):
    country_list = custom_country_list()
    return get_random_items_from_list(country_list, numItems)


def get_country_code(country):
    country_code_dict = custom_country_code_dict()
    country_code = country_code_dict[country]
    return country_code


def get_country_name(search_country_code):
    country_code_dict = custom_country_code_dict()
    for country_name, country_code in country_code_dict.items():
        if country_code == search_country_code:
            return country_name


def get_country_currency_code(country='singapore'):
    default = None
    convert_dict = {'singapore': 'SGD', 'new zealand': 'NZD', 'united states': 'USD', 'europe': 'EUR',
                    'china': 'CNY', 'japan': 'JPY', default: 'UNDEFINED'}
    return convert_dict.get(country.strip().lower(), convert_dict.get(default))


def generate_currency_code_and_exchange_rate(includeSGD=True, exchange_rate_decimals=9):
    currencyCode = get_random_currency_code(includeSGD)

    if currencyCode == "SGD" or currencyCode == "NZD":
        exchangeRate = generate_random_exchange_rate(1, 1, exchange_rate_decimals)
    elif currencyCode == "USD" or currencyCode == "EUR" or currencyCode == "GBP":
        exchangeRate = generate_random_exchange_rate(1, 2.1, exchange_rate_decimals)
    else:
        exchangeRate = generate_random_exchange_rate(0.000000001, 1, exchange_rate_decimals)

    return currencyCode, exchangeRate


def get_random_currency_code(includeSGD=False):
    currencyCode = ["USD", "EUR", "NZD", "GBP", "CNY", "JPY", "THB"]
    if includeSGD:
        currencyCode.append('SGD')
    return random.choice(currencyCode)


def get_random_valid_address(is_valid=True, is_no_block=True, is_multiple=True, is_long_street=True, is_level_unit_random=True):
    """
            Order of array sequence (top->bottom, left->right)
                <Building Name>     SandCrawler,
                <Block> <Street>    1 Fusionopolis View,
                #<Level>-<Unit>     #08-01
                Singapore <Postal>  Singapore 138577
                <number of postal code results>
    """
    POSTAL_CODE_LIST_TYPE_VALID = 'valid'
    POSTAL_CODE_LIST_TYPE_NO_BLOCK = 'no_block'
    POSTAL_CODE_LIST_TYPE_MULTIPLE = 'multiple'
    POSTAL_CODE_LIST_TYPE_LONG_STREET = 'long_street'
    POSTAL_CODE_LIST_TYPES = [POSTAL_CODE_LIST_TYPE_VALID, POSTAL_CODE_LIST_TYPE_NO_BLOCK,
                              POSTAL_CODE_LIST_TYPE_MULTIPLE, POSTAL_CODE_LIST_TYPE_LONG_STREET]
    # Randomise Level, Unit
    LEVEL_RANDOM = str(random.randint(10, 99)) + random.choice(string.ascii_uppercase) if is_level_unit_random else '6I9'
    UNIT_RANDOM = str(random.randint(1000, 9999)) + random.choice(string.ascii_uppercase) if is_level_unit_random else '2912G'

    POSTAL_CODE_LIST = {
        POSTAL_CODE_LIST_TYPE_VALID: [
            ['SANDCRAWLER', '1', 'FUSIONOPOLIS VIEW', LEVEL_RANDOM, UNIT_RANDOM, '138577', 1],
            ['GALAXIS', '1', 'FUSIONOPOLIS PLACE', LEVEL_RANDOM, UNIT_RANDOM, '138522', 1],
            ['MAPLETREE BUSINESS CITY', '10', 'PASIR PANJANG ROAD', LEVEL_RANDOM, UNIT_RANDOM, '117438', 1],
            ['PLAZA 8 @ CBP', '1', 'CHANGI BUSINESS PARK CRESCENT', LEVEL_RANDOM, UNIT_RANDOM, '486025', 1],
            ['SEMBAWANG SHOPPING CENTRE', '604', 'SEMBAWANG ROAD', LEVEL_RANDOM, UNIT_RANDOM, '758459', 1]
        ],
        POSTAL_CODE_LIST_TYPE_NO_BLOCK: [
            ['MANDAI GOLF COURSE', '--', 'MANDAI ROAD - TRACK 7', LEVEL_RANDOM, UNIT_RANDOM, '779384', 1],
            ['CALDECOTT BROADCAST CENTRE', '--', 'ANDREW ROAD', LEVEL_RANDOM, UNIT_RANDOM, '299939', 1],
            ['NATIONAL STADIUM', '--', 'GUILLEMARD CRESCENT', LEVEL_RANDOM, UNIT_RANDOM, '390000', 1],
            ['ISTANA', '--', 'ORCHARD ROAD', LEVEL_RANDOM, UNIT_RANDOM, '238823', 1],
            ['SPECIAL OPERATIONS COMMAND', '--', 'QUEENSWAY', LEVEL_RANDOM, UNIT_RANDOM, '149051', 1]
        ],
        POSTAL_CODE_LIST_TYPE_MULTIPLE: [
            ['UPPER THOMSON SHOPHOUSES', '908', 'UPPER THOMSON ROAD', LEVEL_RANDOM, UNIT_RANDOM, '787111', 10],
            ['KING GEORGE\'S SHOPHOUSES', '111', 'KING GEORGE\'S AVENUE', LEVEL_RANDOM, UNIT_RANDOM, '208559', 15],
            ['JLN RIANG SHOPHOUSES', '15', 'JALAN RIANG', LEVEL_RANDOM, UNIT_RANDOM, '358987', 20],
            ['OXLEY RESIDENCES', '26', 'OXLEY ROAD', LEVEL_RANDOM, UNIT_RANDOM, '238620', 24],
            ['TANJONG KATONG SHOPHOUSES', '188-1', 'TANJONG KATONG ROAD', LEVEL_RANDOM, UNIT_RANDOM, '436990', 30]
        ],
        POSTAL_CODE_LIST_TYPE_LONG_STREET: [
            ['ST ENGINEERING HUB', '1', 'ANG MO KIO ELECTRONICS PARK ROAD', LEVEL_RANDOM, UNIT_RANDOM, '567710', 32]
        ]
    }

    address = []
    if is_valid:
        address.extend(POSTAL_CODE_LIST[POSTAL_CODE_LIST_TYPE_VALID])
    if is_no_block:
        address.extend(POSTAL_CODE_LIST[POSTAL_CODE_LIST_TYPE_NO_BLOCK])
    if is_multiple:
        address.extend(POSTAL_CODE_LIST[POSTAL_CODE_LIST_TYPE_MULTIPLE])
    if is_long_street:
        address.extend(POSTAL_CODE_LIST[POSTAL_CODE_LIST_TYPE_LONG_STREET])
    return random.choice(address)


def generate_random_nric(type='Singaporean'):
    """
    Based on the NRIC formula checksum for last character of NRIC
    Returns a random NRIC value generated with the following guidelines:
    1. For Singaporean, First character of NRIC is 'S' or 'T'
       and last character of NRIC can be one from ['J', 'Z', 'I', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A']
    2. For Foreigner, first character of NRIC is 'F' or 'G'
       and last character of NRIC can be one from ['X', 'W', 'U', 'T', 'R', 'Q', 'P', 'N', 'M', 'L', 'K']
    3. If first character is 'T' or 'G' the offset value is 4, else 0
    4. NRIC factor list values [2, 7, 6, 5, 4, 3, 2] are used to randomly pick the last character from the list.
       The factor list numbers are multiplied with a random number (0 to 9) and added to fetch the total.
       The total is then added with the offset value and then divided by 11 (num of characters in the last char list)
       The reminder value from the division is used to fetch the last character of NRIC from the list
    """
    nric_local_firstchar_list = [
        'S', 'T'
    ]
    nric_foreign_firstchar_list = [
        'F', 'G'
    ]
    nric_local_lastchar_list = [
        'J', 'Z', 'I', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A'
    ]
    nric_foreign_lastchar_list = [
        'X', 'W', 'U', 'T', 'R', 'Q', 'P', 'N', 'M', 'L', 'K'
    ]
    nric_factor_list = [
        2, 7, 6, 5, 4, 3, 2
    ]

    if type != 'Foreigner':
        nric_first = get_random_item_from_list(nric_local_firstchar_list)
    else:
        nric_first = get_random_item_from_list(nric_foreign_firstchar_list)

    offset_value = 0
    if nric_first == 'T' or nric_first == 'G':
        offset_value = 4

    nric_numbers = []
    mytotal = 0
    for x in range(7):
        nric_numbers.append(random.randint(0, 9))
        mytotal = mytotal + (nric_factor_list[x] * nric_numbers[x])

    mytotal = mytotal + offset_value
    remainder = mytotal % 11

    if type != 'Foreigner':
        nric_last = nric_local_lastchar_list[remainder]
    else:
        nric_last = nric_foreign_lastchar_list[remainder]

    nric = nric_first
    nric = nric + ''.join(str(num) for num in nric_numbers)
    nric = nric + nric_last

    return nric


def generate_start_and_end_dates(max_years=50, max_days=365):
    """
    Returns a random Start and End date value as 2 separate strings.
    This can be any Year from 1990 up to +50 years by default.
    Time between Start and End dates is randomised but depends on upper limit set by max_days (default: up to 1 year).
    Formatted as dd Mmm yyyy.
    WARNING: Use generate_future_start_and_end_dates if you want only FUTURE dates instead
    WARNING: Use generate_past_start_and_end_dates if you want only PAST dates instead.
    """
    y = random.randint(1990, 1990 + max_years)
    m = random.randint(1, 12)
    d = random.randint(m, calendar.monthrange(y, m)[1])

    days = random.randint(1, max_days)

    start_date = date(y, m, d)
    start_date_formatted = start_date.strftime("%d %b %Y")

    end_date = start_date + timedelta(days=days)
    end_date_formatted = end_date.strftime("%d %b %Y")

    return start_date_formatted, end_date_formatted


def generate_start_and_end_dates_in_range(start, end):
    d1 = datetime.strptime(start, '%d %b %Y')
    d2 = datetime.strptime(end, '%d %b %Y')

    days = (d2 - d1).days

    start_offset = timedelta(days=(random.randint(1, days)))
    end_offset = timedelta(days=(random.randint(1, days)))

    new_start = d1 + start_offset
    new_end = d2 - end_offset

    while new_end < new_start:
        end_offset = timedelta(days=(random.randint(1, days)))
        new_end = d2 - end_offset

    new_start = new_start.strftime("%d %b %Y")
    new_end = new_end.strftime("%d %b %Y")

    return new_start, new_end


def generate_future_start_and_end_dates(max_years=10, max_days=365):
    """
    Returns a random Start and End date value as 2 separate strings.
    These dates are a random FUTURE date which CAN include Today.
    Upper limit of Start date year is set by max_years (default: up to 1 year)
    Time between Start and End dates is randomised but depends on upper limit set by max_days (default: up to 1 year).
    Formatted as dd Mmm yyyy.
    """
    max_years = int(max_years)
    max_days = int(max_days)

    this_year = date.today().year

    y = this_year + random.randint(0, max_years)

    if y == this_year:
        m = random.randint(date.today().month, 12)
        if date.today().day < calendar.monthrange(y, m)[1]:
            d = random.randint(date.today().day, calendar.monthrange(y, m)[1])
        else:
            d = date.today().day
            m = date.today().month
    else:
        m = random.randint(1, 12)
        d = random.randint(m, calendar.monthrange(y, m)[1])

    days = random.randint(1, max_days)

    start_date = date(y, m, d)
    start_date_formatted = start_date.strftime("%d %b %Y")

    end_date = start_date + timedelta(days=days)
    end_date_formatted = end_date.strftime("%d %b %Y")

    return start_date_formatted, end_date_formatted


def generate_past_start_and_end_dates(max_years=10, max_days=365):
    """
    Returns a random Start and End date value as 2 separate strings.
    These dates are a random PAST date UP TO Yesterday.
    Lower limit of Start date year is set by max_years (default: up to 1 year)
    Time between Start and End dates is randomised but depends on upper limit set by max_days (default: up to 1 year).
    Formatted as dd Mmm yyyy.
    """
    this_year = date.today().year

    y = this_year - random.randint(0, max_years)
    if y == this_year:
        m = random.randint(1, date.today().month)
        d = random.randint(calendar.monthrange(y, m)[1], int(date.today().day) - 1)
    else:
        m = random.randint(1, 12)
        d = random.randint(m, calendar.monthrange(y, m)[1])

    days = random.randint(1, max_days)

    start_date = date(y, m, d)
    start_date_formatted = start_date.strftime("%d %b %Y")

    end_date = start_date + timedelta(days=days)
    end_date_formatted = end_date.strftime("%d %b %Y")

    return start_date_formatted, end_date_formatted


def generate_date_based_on_given_date(input_date, max_years=10, max_days=365, max_months=12):
    my_date = datetime.strptime(input_date, '%d/%m/%Y')
    days = random.randint(1, max_days)
    months = random.randint(1, max_months)
    years = random.randint(1, max_years)
    new_date = my_date + timedelta(days=days)
    new_date = new_date + relativedelta.relativedelta(months=months) + relativedelta.relativedelta(years=years)
    my_date_formatted = new_date.strftime("%d/%m/%Y")

    return my_date_formatted


def add_days_to_date(input_date, days_to_add=100):
    my_date = datetime.strptime(input_date, '%d %b %Y')
    time_to_add = timedelta(days=days_to_add)
    new_date = my_date + time_to_add
    new_date_formatted = new_date.strftime("%d %b %Y")

    return new_date_formatted


def add_months_to_date(input_date, months_to_add=3):
    my_date = datetime.strptime(input_date, '%d %b %Y')
    time_to_add = relativedelta.relativedelta(months=months_to_add)
    new_date = my_date + time_to_add
    new_date_formatted = new_date.strftime("%d %b %Y")

    return new_date_formatted


def check_if_past_date(input_date):
    my_date = datetime.strptime(input_date, '%d %b %Y')
    present_date = datetime.now()

    return my_date <= present_date


def calculate_duration_between_dates(date1, date2):
    d1 = datetime.strptime(date1, '%d %b %Y')
    d2 = datetime.strptime(date2, '%d %b %Y')

    days = (d2 - d1).days

    # Using same formula as BGP RoR for calculating duration
    dt = 1 if d2.day >= d1.day else 0
    months = (d2.year * 12 + d2.month) - (d1.year * 12 + d1.month) + dt

    return days, months


def calculate_months_between_dates(date1, date2):
    date_format = "%d/%m/%Y"
    d1 = datetime.strptime(date1, date_format)
    d2 = datetime.strptime(date2, date_format)

    dt = 1 if d2.day > d1.day else 0
    months = (d2.year * 12 + d2.month) - (d1.year * 12 + d1.month) + dt

    return months


def get_future_start_date():
    """
    Returns future start date in dd Mon year format
    """
    start_date = datetime.now() + timedelta(days=random.randint(1, 30))
    start_date_formatted = start_date.strftime("%d %b %Y")
    return start_date_formatted


def get_current_year():
    now = datetime.now()
    current_year = now.year
    return current_year


def date_difference_in_months(d1, d2):
    date1 = datetime.strptime(d1, '%d %b %Y')
    date2 = datetime.strptime(d2, '%d %b %Y')
    diff = (date1.year - date2.year) * 12 + date1.month - date2.month
    diff_days = (date1.day - date2.day)
    if diff_days >= 0:
        diff = diff + 1
    else:
        diff = diff

    print(diff, end=" ")
    if diff == 0:
        return 1
    else:
        return diff


def move_focus_to_element_position(locator, waitTime=10):
    selenium = BuiltIn().get_library_instance('SeleniumLibrary')
    selenium.wait_until_element_is_visible(locator, waitTime)
    ele = selenium.find_element(locator, True, True, None)
    loc = ele.location
    y = loc.get('y')
    selenium.execute_javascript('window.scrollTo(0,' + str(y) + ')')


def format_money(value, places=2, curr='', sep=',', dp='.',
                 pos='', neg='-', trailneg=''):
    """Convert Decimal to a money formatted string.

    places:  required number of places after the decimal point
    curr:    optional currency symbol before the sign (may be blank)
    sep:     optional grouping separator (comma, period, space, or blank)
    dp:      decimal point indicator (comma or period)
             only specify as blank when places is zero
    pos:     optional sign for positive numbers: '+', space or blank
    neg:     optional sign for negative numbers: '-', '(', space or blank
    trailneg:optional trailing minus indicator:  '-', ')', space or blank

    >>> d = Decimal('-1234567.8901')
    >>> format_money(d, curr='$')
    '-$1,234,567.89'
    >>> format_money(d, places=0, sep='.', dp='', neg='', trailneg='-')
    '1.234.568-'
    >>> format_money(d, curr='$', neg='(', trailneg=')')
    '($1,234,567.89)'
    >>> format_money(Decimal(123456789), sep=' ')
    '123 456 789.00'
    >>> format_money(Decimal('-0.02'), neg='<', trailneg='>')
    '<0.02>'

    """
    q = Decimal(10) ** -places  # 2 places --> '0.01'
    sign, digits, exp = Decimal(value).quantize(q).as_tuple()
    result = []
    digits = map(str, digits)
    build, next_char = result.append, digits.pop
    if sign:
        build(trailneg)
    for i in range(places):
        build(next_char() if digits else '0')
    build(dp)
    if not digits:
        build('0')
    i = 0
    while digits:
        build(next_char())
        i += 1
        if i == 3 and digits:
            i = 0
            build(sep)
    build(curr)
    build(neg if sign else pos)
    return ''.join(reversed(result))


def generate_random_exchange_rate(low=0, high=6, exchange_rate_decimals=9):
    custom_rate = str(generate_random_float_with_custom_decimal(low, high, exchange_rate_decimals))
    return custom_rate


def list_of_list_should_contain_cost_at_index(list_costlist, string_cost_with_prefix, index):
    string_cost_with_no_prefix = string_cost_with_prefix.split("SGD ")[1]
    for costlist in list_costlist:
        if format_money(Decimal(costlist[int(index)])) == string_cost_with_no_prefix:
            return True
    raise AssertionError("'%s' not found in list of list" % string_cost_with_prefix)


def list_should_contain_cost(string_costlist, string_cost_with_prefix):
    string_cost_with_no_prefix = string_cost_with_prefix.split("SGD ")[1]
    for string_cost in string_costlist:
        if format_money(Decimal(string_cost)) == string_cost_with_no_prefix:
            return True
    raise AssertionError("'%s' not found in: %s" % (string_cost_with_prefix, ''.join(string_costlist)))


def pdf_read_to_text():
    download_path = get_download_folder()
    os.chdir(download_path)
    files = sorted(os.listdir(os.getcwd()), key=os.path.getmtime)
    newest = files[-1]
    downloaded_file = str(download_path) + '/' + str(newest)
    file_data = parser.from_file(downloaded_file)
    text = file_data['content']
    return text


def pdf_read_to_text_with_filename(filename):
    download_path = os.path.abspath(os.curdir)
    downloaded_file = str(download_path) + '/' + str(filename)
    print('Downloaded File Path: ', downloaded_file)
    file_data = parser.from_file(downloaded_file)
    text = file_data['content']
    return text


def split_string_with_splitchar(str, splitstr1, splitstr2):
    print('Splitstr1: ', splitstr1)
    print('Splitstr2: ', splitstr2)
    tempstr1 = str.split(splitstr1)[1]
    templist = tempstr1.split(splitstr2)[0]
    templist = templist.replace('\n\n', '\n')
    templist = templist.split('\n')
    return templist


def verify_pdf_has_expected_text(pdftext, expectedtext):
    nomatchflag = False
    for value in expectedtext:
        value = value.replace(',', '')
        flag = False
        for t in pdftext:
            if value in t:
                print('Match Found  <Expected> ', value, '   <Actual>   ', t)
                flag = True
                break
        if not flag:
            nomatchflag = True
            print('No Match Found for: ', value)
    if nomatchflag:
        raise AssertionError("Expected Text Not Found in the PDF file.")


def read_excel_column_data_from_downloads(file_name, sheet_name, header_row, index_col_name, ref_id, col_name):
    download_path = get_download_folder()
    downloaded_file = str(download_path) + '/' + str(file_name)
    df = pd.read_excel(downloaded_file, header=int(header_row), index_col=str(index_col_name),
                       sheetname=str(sheet_name))
    return df.loc[ref_id, col_name]


def get_download_folder():
    home = os.path.expanduser("~")
    return os.path.join(home, "Downloads")


def get_matches_from_two_lists(list1, list2):
    matches = []
    unique_list1 = np.unique(list1)
    unique_list2 = np.unique(list2)
    for list1 in unique_list1:
        for list2 in unique_list2:
            if list1 == list2:
                matches.append(list1)
    return matches


def verify_date1_greater_than_date2(date1, date2):
    newdate1 = time.strptime(date1, "%d/%m/%Y")
    newdate2 = time.strptime(date2, "%d/%m/%Y")

    return newdate1 > newdate2


def convert_string_to_camelcase(text):
    text = sub(r"(_|-)+", " ", text).title().replace(" ", "")
    return text[0].lower() + text[1:]
