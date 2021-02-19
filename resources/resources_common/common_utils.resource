*** Settings ***
Library    Collections
Library    DateTime
Library    String
Library    common_custom_keywords.py
Library    SeleniumLibrary
Resource    common_variables.resource

*** Keywords ***
#####     BROWSER KEYWORDS     #####
Open Chrome Browser
    [Documentation]    Starts the chrome driver for execution of scripts. Also sets the default timeout to 180 seconds.

    ${chrome_options}=   Set Chrome Options
    Create Webdriver    Chrome    chrome_options=${chrome_options}
    Set Selenium Timeout   ${SELENIUM_TIMEOUT}


#####     TEST SUITE KEYWORDS     #####
Fail Workflow If Previous Step Failed
    [Documentation]    Use this in [Setup] to save time when a critical workflow has failed.
    ...                Does not fail when test case is tagged with NON_CRIT (Use [Tags]  ${NON_CRIT})
    ...                 - e.g. WF1 (crit) > PASS > WF2 (non-crit) > FAIL > WF3 (crit) > CONTINUES
    ...                 - e.g. WF1 (crit) > FAIL > WF2 (non-crit) > STOP & FAIL > WF3 (crit) > STOP & FAIL
    ...                First test case is assumed critical but it's possible to be non-critical
    ...                Just ensure that first non-critical test case has [Setup] Fail Workflow If Previous Step Failed
    ...                 - e.g. WF1 (non-crit) w/ [Setup] > FAIL > WF2 (non-crit) > CONTINUES & FAIL > WF3 (crit) > CONTINUES
    ...                 - e.g. WF1 (non-crit) w/o [Setup] > FAIL > WF2 (non-crit) > STOP & FAIL > WF3 (crit) > STOP & FAIL
    [Arguments]    ${status}=${PREV_TEST_STATUS}    ${critical}=${IS_PREV_TEST_CRIT}

    ${prev_crit_status}=    Set Variable If    "${critical}" == 'True'    ${status}    ${PREV_CRIT_TEST_STATUS}
    Set Suite Variable    ${PREV_CRIT_TEST_STATUS}    ${prev_crit_status}
    Log    Previous Test Case: ${status} | Is Previous Test Critical: ${critical} | Last Critical Test Case: ${PREV_CRIT_TEST_STATUS}
    Run Keyword If    ("${status}" == 'FAIL' and "${critical}" == 'True') or "${PREV_CRIT_TEST_STATUS}" == 'FAIL'    FAIL    AUTOMATIC FAILURE: A previous critical step in this workflow has failed!

    ${found}=    Get Index From List    ${TEST_TAGS}    ${NON_CRIT}
    ${crit}=    Set Variable If    ${found} > -1    False    True
    Set Suite Variable    ${IS_PREV_TEST_CRIT}    ${crit}


#####     COMPARISON KEYWORDS     #####
# TODO: To integrate with NON_CRIT label to Run Keyword And Ignore Error instead???
Compare String Values
    [Documentation]    Verifies if expected_value==actual_value using 'Should Be Equal As Strings' keyword. Pass in string_name for logging purpose.
    ...    By default failsafe=False, setting to True will prevent subsequent keywords to continue running when this keyword have failed
    ...    Purpose: allow multiple Compare String Values to run consecutively without failure interruption (aggregate failure validations)
    [Arguments]    ${string_name}    ${expected_value}    ${actual_value}    ${failsafe}=${false}

    ${default}=    Set Variable    Should Be Equal As Strings    "${expected_value}"    "${actual_value}"    [${string_name}] Expected vs Actual
    ${keyword}=    Run Keyword If    ${failsafe}==${false}    Set Variable    Run Keyword And Continue On Failure    @{default}
    ...                       ELSE    Set Variable    ${default}
    Log    ${string_name}: <Expected> ${expected_value} | <Actual> ${actual_value}    console=True
    Run Keyword Unless    r"""${expected_value}"""=='${EMPTY}'
    ...    @{keyword}


Compare Numeric Values
    [Documentation]    Verifies if expected_value==actual_value using 'Should Be Equal As Integers' keyword. Pass in num_name for logging purpose.
    ...    By default float=False, setting to True will compare the value using Should Be Equal As Numbers (Will truncate number to 2 decimal place)
    ...    By default failsafe=False, setting to True will prevent subsequent keywords to continue running when this keyword have failed
    ...    Purpose: allow multiple Compare Numeric Values to run consecutively without failure interruption (aggregate failure validations)
    [Arguments]    ${num_name}    ${expected_value}    ${actual_value}    ${float}=${false}    ${failsafe}=${false}

    ${expected_value}=    Convert To String    ${expected_value}
    ${expected_value}=    Replace String      ${expected_value}    ,    ${EMPTY}

    ${actual_value}=    Convert To String    ${actual_value}
    ${actual_value}=    Replace String      ${actual_value}    ,    ${EMPTY}

    ${expected_value}=    Run Keyword If    ${float}    Truncate To 2 Decimal Number    ${expected_value}
    ...                             ELSE    Set Variable    ${expected_value}
    ${actual_value}=    Run Keyword If    ${float}    Truncate To 2 Decimal Number    ${actual_value}
    ...                             ELSE    Set Variable    ${actual_value}
    ${compare_int}=    Set Variable    Should Be Equal As Integers    ${expected_value}    ${actual_value}    [${num_name}] Expected vs Actual
    ${compare_float}=    Set Variable    Should Be Equal As Numbers    ${expected_value}    ${actual_value}    [${num_name}] Expected vs Actual
    ${compare_keyword}=    Set Variable If    not ${float}    ${compare_int}    ${compare_float}
    ${keyword}=    Run Keyword If    ${failsafe}==${false}    Set Variable    Run Keyword And Continue On Failure    @{compare_keyword}
    ...                       ELSE    Set Variable    ${compare_keyword}
    Log    ${num_name}: <Expected> ${expected_value} | <Actual> ${actual_value}    console=True
    Run Keyword Unless    r"${expected_value}"=='${EMPTY}'
    ...    @{keyword}


Compare List Values
    [Documentation]    Verifies if expected_value==actual_value using 'Lists Should Be Equal' keyword. Pass in list_name for logging purpose.
    ...    WARNING: No sorting is done in this keyword due to potential of mixed typing (Use Compare List instead)
    ...    ASSUMPTIONS: All values in the list are of SAME TYPE; Lists compared are ORDERED aka SORTED before passing in
    ...    By default failsafe=False, setting to True will prevent subsequent keywords to continue running when this keyword have failed
    ...    Purpose: allow multiple Compare String Values to run consecutively without failure interruption (aggregate failure validations)
    ...    By default verbose=True, setting to True will find the missing values in the list and append as part of the error logging
    ...    By default debug=False, setting to True will include debug message from Finding Missing List Values (provided verbose=True) and append as part of the error logging
    [Arguments]    ${list_name}    ${expected_list}    ${actual_list}    ${failsafe}=${false}    ${verbose}=${true}    ${debug}=${false}

    Should Be List    ${expected_list}
    Should Be List    ${actual_list}
    ${len_e}=    Get Length    ${expected_list}
    ${len_a}=    Get Length    ${actual_list}
    Return From Keyword If    ${len_e}==0 and ${len_a}==0    ${expected_list}    ${actual_list}

    ${list_name}=    Convert To String    ${list_name}

    ${missing_expected}    ${missing_actual}    ${missing_err}=    Run Keyword If    ${verbose}    Find Missing List Values    ${list_name}    ${expected_list}    ${actual_list}    ${debug}
    ${list_to_check}=    Run Keyword If    ${verbose}    Create List    ${missing_expected}    ${missing_actual}
    ...                            ELSE    Create List    ${expected_list}    ${actual_list}

    ${default_err}=    Set Variable    [Compared]: ${list_name} List\n| <${len_e} Expected>: ${expected_list}\n| <${len_a} Actual>:${space*2} ${actual_list}
    ${verbose_err}=    Set Variable If    ${verbose}    | ${missing_err}\n| ${default_err}    ${default_err}
    ${msg}=    Set Variable    -- ${list_name} List -- Expected vs Actual\n${verbose_err}

    ${default}=    Set Variable    Lists Should Be Equal    @{list_to_check}    ${msg.strip()}
    ${keyword}=    Run Keyword If    ${failsafe}==${false}    Set Variable    Run Keyword And Continue On Failure    @{default}
    ...                       ELSE    Set Variable    ${default}
    Log    ${default_err}    console=True
    Run Keyword    @{keyword}

    [Return]    @{list_to_check}


Compare List
    [Documentation]    Recursively compares List and its layers of Sublist using 'Compare List Values' keyword. Pass in list_name for logging purpose.
    ...    ASSUMPTIONS: Will sort list even if it contains mixed typing
    ...    By default failsafe=False, setting to True will prevent subsequent keywords to continue running when this keyword have failed
    ...    Purpose: allow multiple Compare List Values to run consecutively without failure interruption (aggregate failure validations)
    ...    By default verbose=True, setting to True will find the missing values in the list and append as part of the error logging
    ...    By default debug=False, setting to True will include debug message from Finding Missing List Values (provided verbose=True) and append as part of the error logging
    [Arguments]    ${list_name}    ${expected_list}    ${actual_list}    ${failsafe}=${false}    ${verbose}=${true}    ${debug}=${false}

    ${list_name}=    Convert To String    ${list_name}
    Log To Console    ***** Comparing ${list_name} List *****
    # Split w/ Sort included
    ${elist}    ${non_elist}=    Split List Based On Type    ${expected_list}
    ${alist}    ${non_alist}=    Split List Based On Type    ${actual_list}
    # Compare Non-List
    Compare List Values    ${non_elist}    ${non_elist}    ${non_alist}    ${failsafe}    ${verbose}    ${debug}
    # End condition
    ${len_e}=    Get Length    ${elist}
    ${len_a}=    Get Length    ${alist}
    ${same_length}=    Run Keyword And Return Status    Should Be Equal As Integers    ${len_e}    ${len_a}
    Run Keyword And Return If    ${len_e}==0 or ${len_a}==0 or not ${same_length}
    ...    Compare List Values    ${elist}    ${elist}    ${alist}    ${failsafe}    ${verbose}    ${debug}

    FOR    ${i}    IN RANGE    0    ${len_e}
        ${e}=    Set Variable    ${elist[${i}]}
        ${a}=    Set Variable    ${alist[${i}]}
        Compare List    ${e}    ${e}    ${a}    ${failsafe}    ${verbose}    ${debug}
    END


#####     DATA STRUCTURE KEYWORDS     #####
Convert JSON List To List
    [Documentation]    Converts list of JSON or Dict values to list based on given key
    ...                e.g. [{'key1': 'first', 'key2': 'second'}, {'key1': 'third', 'key2': 'fourth'}]
    ...                Given keys=key1 -> ['first', 'third']
    ...                Given keys=key1, key2 -> [['first', 'third'], ['second', 'fourth']]
    [Arguments]    ${dict_list}    @{keys}

    Should Be List    ${dict_list}
    ${result}=    Create List
    FOR    ${dict}    IN    @{dict_list}
        Should Be Dictionary    ${dict}
        ${values}=    Convert JSON Keys To Values List    ${dict}    @{keys}
        Append To List    ${result}    ${values}
    END

    Sort List    ${result}

    [Return]    ${result}


Convert JSON Keys To Values List
    [Documentation]    Convert JSON Keys Into Values List
    ...                e.g. {'key1': 'first', 'key2': 'second', 'key3': 'third'}
    ...                Given keys=key1, key3 -> ['first', 'third']
    [Arguments]    ${dict}    @{keys}

    Should Be Dictionary    ${dict}
    ${l}=    Get Length    ${keys}
    Return From Keyword If    ${l} == 1    ${dict['${keys[0]}']}

    ${values}=    Create List
    FOR    ${key}    IN    @{keys}
        Append To List    ${values}    ${dict['${key}']}
    END

    [Return]    ${values}


Convert Date List
    [Documentation]    Convert a list of dates into defined format
    ...     Uses DateTime library to convert
    ...     Applicable to 2 levels of date list only
    ...     e.g. ['2020/10/20', '2020/11/21'] OR [['date1', '2020/10/20'], ['date2', '2020/11/21']]
    ...     If date_format and result_format is not defined, it defaults to
    ...         > 2019-02-21T15:37:38.000+08:00 => 21 Feb 2019 03:38 PM
    ...     For 2 levels of date list, specify the index of where the dates are stored
    ...         > If no index is defined, it defaults to the first element
    ...     It is assumed that all dates are in the same format and located at the same index
    [Arguments]    ${dates}    ${date_format}=%Y-%m-%dT%H:%M:%S.%f%z    ${result_format}=%d %b %Y %I:%M %p   ${index}=${0}

    Should Be List    ${dates}
    ${converted_dates}=    Create List
    FOR    ${date}    IN    @{dates}
        ${is_list}=    Run Keyword And Return Status    Should Be List    ${date}
        ${date_var}=    Set Variable If    ${is_list}    date[${index}]    date
        ${convert_date}=    Convert Date    ${${date_var}}    date_format=${date_format}    result_format=${result_format}
        Run Keyword If    ${is_list}    Set List Value   ${date}    ${index}    ${convert_date}
        ${convert_date}=    Set Variable If    ${is_list}    ${date}    ${convert_date}
        Append To List    ${converted_dates}    ${convert_date}
    END

    [Return]    ${converted_dates}


Flatten List
    [Documentation]  Flattens list containing lists of items base on index given
    ...                  - e.g. [['a', 'a1', 'a2'], ['b', 'b1', 'b2'], ['c', 'c1', 'c2']]
    ...              Order of the index matters
    ...                  - indexes=0,2 -> ['a', 'a2', 'b', 'b2', 'c', 'c2']
    ...                  - indexes=2,0 -> ['a2', 'a', 'b2', 'b', 'c2', 'c']
    ...                  - indexes=-1 -> ['a2', 'b2', 'c2']
    ...              If no index is given, every element will be consider
    ...                  - no parameter -> ['a', 'a1', 'a2', 'b', 'b1', 'b2', 'c', 'c1', 'c2']
    ...              Does not work on single level list: ['a', 'b', 'c']
    ...              Only works on two layers of list. See above example.
    ...              List of list length must be the same throughout the conversion
    [Arguments]     ${tuple_or_list}    @{indexes}

    Should Be List    ${tuple_or_list}

    ${result}=    Create List
    FOR    ${l}    IN    @{tuple_or_list}
        ${list}=    Get Multiple From List    ${l}    @{indexes}
        Append To List  ${result}     @{list}
    END

    Log    ${result}

    [Return]  ${result}


Get Multiple From List
    [Documentation]    Similar to Get From List but with multiple indexes
    [Arguments]     ${list}    @{indexes}

    Should Be List    ${list}
    ${len_i}=    Get Length    ${indexes}
    Return From Keyword If    ${len_i}==0    ${list}

    ${len_l}=    Get Length    ${list}
    ${indexes}=    Remove Duplicates    ${indexes}
    ${result}=    Create List
    FOR    ${i}    IN    @{indexes}
        ${len_l}=    Get Length    ${list}
        Run Keyword If    ${i} > ${len_l-1}    Fail    Inaccessible Index ${i} on List(${len_l}): ${list}
        ${value}=    Get From List    ${list}    ${i}
        Append To List    ${result}    ${value}
    END

    Log    ${result}

    [Return]    ${result}


Find Missing List Values
    [Documentation]    Finds missing values between two list
    ...    - Enable debug mode to print out all values from expected and actual list
    ...    - Returns missing expected values (list), missing actual values (list) and the logs (string) in that order
    [Arguments]    ${list_name}    ${expected_list}    ${actual_list}    ${debug}=${false}

    Should Be List    ${expected_list}
    Should Be List    ${actual_list}
    ${list_name}=    Convert To String    ${list_name}
    ${missing_e}=    Create List
    ${missing_a}=    Copy List    ${actual_list}
    ${debug_output}=    Set Variable    ***** [DEBUG] Find Missing List Values *****

    FOR    ${e}    IN    @{expected_list}
        ${i}=    Get Index From List    ${missing a}    ${e}
        ${debug_output}=    Run Keyword If    ${debug} and ${i} > -1    Catenate    SEPARATOR=\n    ${debug_output}
        ...                                                                                         Found ${e}\nIn Actual List: ${missing_a}\nAt Index: ${i}
        ...                        ELSE IF    ${debug} and ${i} < 0    Catenate    SEPARATOR=\n    ${debug_output}
        ...                                                                                        Unable to Find ${e}\nAdding to Missing Expected List: ${missing_e}
        ...                           ELSE    Set Variable    ${debug_output}
        Run Keyword If    ${i} > -1    Remove From List    ${missing_a}    ${i}
        ...       ELSE    Append To List    ${missing_e}    ${e}
    END
    ${len_e}=    Get Length    ${missing_e}
    ${len_a}=    Get Length    ${missing_a}
    ${missing_log}=    Set Variable If    ${len_e} > 0 or ${len_a} > 0    [Missing]: ${list_name} List\n| <${len_e} Expected>: ${missing_e}\n| <${len_a} Actual>:\t${missing_a}
    ...    [${len_a} Missing]: ${list_name} List
    Log    ${missing_log}    console=True

    # DEBUG
    # Original Expected
    ${debug_output}=    Catenate    SEPARATOR=\n    ${debug_output}
    ...    [Expected ${list_name}]:
    ${i}=    Set Variable    ${1}
    FOR    ${e}    IN    @{expected_list}
        ${debug_output}=    Catenate    SEPARATOR=\n    ${debug_output}
        ...    | ${list_name} \#${i}: ${e}
        ${i}=    Set Variable    ${i+1}
    END
    # Original Actual
    ${debug_output}=    Catenate    SEPARATOR=\n    ${debug_output}
    ...    [Actual ${list_name}]:
    ${i}=    Set Variable    ${1}
    FOR    ${a}    IN    @{actual_list}
        ${debug_output}=    Catenate    SEPARATOR=\n    ${debug_output}
        ...    | ${list_name} \#${i}: ${a}
        ${i}=    Set Variable    ${i+1}
    END
    Run Keyword If    ${debug}    Log    ${debug_output.strip()}    console=True
    ${debug_output}=    Set Variable If    ${debug}    ${debug_output}    ${empty}
    ${missing_log}=    Catenate    SEPARATOR=\n    ${missing_log}
    ...    ${debug_output}

    [Return]    ${missing_e}    ${missing_a}    ${missing_log.strip()}


Sort Mixed List
    [Documentation]    Sort a list with mixed type (Similar to Sort List)
    ...                Unlike Sort List, it returns the sorted list, hence keeping the order of the original
    ...                Default precedence: Number, String, List, Dict
    ...                    - Given: ['a2', ['b', 'b1', 'b2'], {c: c1, d: d1}, 2.5]
    ...                    - Output: ['a2', 2.5, ['b', 'b1', 'b2'], {c=c1, d=d1}]
    [Arguments]    ${list}

    Should Be List    ${list}
    ${precedence}=    Create List    String    Number    List    Dict
    ${result}=    Create List

    FOR    ${p}    IN    @{precedence}
        ${type}    ${non_type}=    Split List Based On Type    ${list}    ${p}
        ${list}=    Set Variable    ${non_type}
        Sort List    ${type}
        Append To List    ${result}    @{type}
    END

    Log    Sorted Mixed List: ${result}

    [Return]    ${result}


Split List Based On Type
    [Documentation]    Split list into given-type list and non-type list
    ...                    > e.g. type=List -> Output: list list & non-list list
    ...                    > e.g. type=String -> Output: string list & non-string list
    ...                Available type arguments: List (includes Tuple), String, Number (Integer/Float), Dict (includes JSON)
    [Arguments]    ${list}    ${type}=List

    ${check}=    Set Variable If    "${type}"=='String'    Should Be String
    ...                             "${type}"=='Number'    Should Be Numeric
    ...                             "${type}"=='Dict'    Should Be Dictionary    Should Be List

    ${type_array}=    Create List
    ${non_array}=    Create List
    FOR    ${l}    IN    @{list}
        ${is_type}=    Run Keyword And Return Status    ${check}    ${l}
        ${to_append}=    Set Variable If    not ${is_type}    non_array    type_array
        Append To List    ${${to_append}}    ${l}
    END

    Sort List    ${type_array}
    Log    Original Array: ${list}\n${type} Array: ${type_array}\nNon-${type} Array: ${non_array}

    [Return]    ${type_array}    ${non_array}


#####     TYPE CHECK KEYWORDS     #####
Should Be List
    [Arguments]    ${list}
    ${err}=    Set Variable    ${list} is not List or List-like
    Should Not Be String    ${list}    ${err}
    ${status}=    Evaluate    type(${list})==list or type(${list})==tuple
    Run Keyword If    ${status}==${false}    Fail    ${err}


Should Be Dictionary
    [Arguments]    ${dict}
    ${err}=    Set Variable    ${dict} is not Dictionary or JSON-formatted
    Should Not Be String    ${dict}    ${err}
    ${status}=    Evaluate    type(${dict})==dict
    Run Keyword If    ${status}==${false}    Fail    ${err}


Should Be Numeric
    [Arguments]    ${num}
    ${err}=    Set Variable    ${num} is not a Number
    Should Not Be String    ${num}    ${err}
    ${status}=    Evaluate    type(${num})==float or type(${num})==int
    Run Keyword If    ${status}==${false}    Fail    ${err}


#####     MISC KEYWORDS     #####
Get Current DateTime In Local Time
    [Documentation]    Returns the current Date Time value in local time. The result format can be passed in as input argument.
    ...    Returns the formatted current Date Time value as a String.
    [Arguments]    ${result_format}=%Y%m%d%H%M%S

    ${date}=    Get Current Date
    ${datetime}=    Convert Date    ${date}    result_format=${result_format}
    ${datetime}=    Convert To String    ${datetime}

    [Return]    ${datetime}


Format Appian Address
    [Documentation]    Reusable method to format address to Appian-compatible string
    ...                Use in tandem with Parse JSON Address
    ...                <Building Name>     SandCrawler,
    ...                <Block> <Street>    1 Fusionopolis View,
    ...               \#<Level>-<Unit>    \#08-01
    ...                Singapore <Postal>  Singapore 138577
    [Arguments]   ${building}   ${block}   ${street}   ${level}   ${unit}   ${postal}   ${separator}=,${SPACE}\n

    ${building_name}=    Set Variable If    "${building}"=='${empty}' or "${building}"=='${none}'    ${EMPTY}   ${building}${separator}
    ${block}=    Set Variable If    "${block}"=='${none}'    ${EMPTY}    ${block}
    ${level_unit}=    Set Variable If    "${level}"=="" or "${unit}"==""   ${EMPTY}    \#${level}-${unit}${separator}
    ${address}=    Run Keyword If    "${level}"=="None"
    ...    Set Variable   ${building_name}${block} ${street}${separator}SINGAPORE ${postal}
    ...    ELSE    Set Variable   ${building_name}${block} ${street}${separator}${level_unit}SINGAPORE ${postal}
    Log    ${address}

    [Return]   ${address}


Parse JSON Address
    [Documentation]    Reusable method to parse address in JSON returned from RoR
    ...                Use in tandem with Format Appian Address
    ...                Returns the following: building name, block, street, level, unit, postal in that order
    [Arguments]    ${addr}

    Should Be Dictionary    ${addr}
    ${building}=    Set Variable    ${addr['building_name']}
    ${block}=    Set Variable    ${addr['block']}
    ${street}=    Set Variable    ${addr['street']}
    ${level}=    Set Variable    ${addr['level']}
    ${unit}=    Set Variable    ${addr['unit']}
    ${postal}=    Set Variable    ${addr['postal']}

    ${building}=    Set Variable If    '${building}'=='None'    ${empty}    ${building}

    [Return]    ${building}    ${block}    ${street}    ${level}    ${unit}    ${postal}


Truncate To 2 Decimal Number
    [Documentation]    Checks for repeating decimal (Python floating point issue) then rounds up e.g 90785.43*62=5628696.659999999 ==> 5628696.66
    ...                Else will truncate extra decimals beyond 2 e.g 92082.72*0.358418053*26=858106.8396509483 ==> 858106.83
    ...                Applicable to:
    ...                    > 12 -> 12.00
    ...                    > 12.3 -> 12.30
    ...                    > 12.34 -> 12.34
    ...                    > 12.3456 -> 12.34
    ...                    > 12.3499 -> 12.35
    [Arguments]    ${number}

    ${number}=    Convert To String     ${number}
    @{check_decimal_places}=    Split String    ${number}    .

    # Account for no decimal place - e.g. 60
    ${have_decimal}=    Get Length    ${check_decimal_places}
    ${have_decimal}=    Set Variable If    ${have_decimal}==2    ${true}    ${false}
    # No decimal
    Return From Keyword If    not ${have_decimal}    ${number}.00

    # Have decimal
    ${decimal_places}=    Get Length    ${check_decimal_places[1]}
    Return From Keyword If    ${decimal_places}==2    ${number}
    Return From Keyword If    ${decimal_places}==1    ${number}0

    ${extra_decimal_places}=    Evaluate    ${decimal_places}-2

    ${extra_digits}=    Get Substring    ${number}    -${extra_decimal_places}
    ${extra_digits}=    Convert To Number    ${extra_digits}

    ${repeating_num}=    Evaluate    "9"*(${extra_decimal_places}-1)
    ${repeating_num}=    Convert To Number    ${repeating_num}0
    ${repeating_num}=    Set Variable If     ${extra_decimal_places}>1    ${repeating_num}    9

    ${precise_number}=    Run Keyword If    ${extra_digits}>${repeating_num} and ${extra_decimal_places}>2    Convert To Number    ${number}    2

    ${precise_number}=     Run Keyword If    ${extra_digits}>${repeating_num} and ${extra_decimal_places}>2   Convert To String     ${precise_number}
    @{check_decimal_places_pn}=     Run Keyword If    ${extra_digits}>${repeating_num} and ${extra_decimal_places}>2    Split String    ${precise_number}    .
    ${decimal_places_pn}=     Run Keyword If    ${extra_digits}>${repeating_num} and ${extra_decimal_places}>2    Get Length    ${check_decimal_places_pn[1]}

    Return From Keyword If    ${extra_digits}>${repeating_num} and ${decimal_places_pn}==2 and ${extra_decimal_places}>2    ${precise_number}
    Return From Keyword If    ${extra_digits}>${repeating_num} and ${decimal_places_pn}==1 and ${extra_decimal_places}>2    ${precise_number}0

    ${number}=    Get Substring    ${number}    ${EMPTY}    -${extra_decimal_places}

    [Return]    ${number}


Download and Verify Text In PDF
    [Documentation]    Used to Download and Verify Text In PDF
    [Arguments]    ${pdf_url}    ${text_to_verify}

    Go To    ${pdf_url}
    Sleep    10s
    ${pdf_content}=    Pdf Read To Text
    Log    ${pdf_content}    console=True
    Should Contain    ${pdf_content}    ${text_to_verify}    ignore_case=True


Verify Column Data In Excel
    [Documentation]    Used to Verify Column Data In Excel
    [Arguments]    ${file_name}    ${sheet_name}    ${header_row}    ${index_col_name}    ${ref_id}    ${col_name}    ${exp_col_value}

    ${col_value}=    Read Excel Column Data From Downloads    ${file_name}    ${sheet_name}    ${header_row}    ${index_col_name}    ${ref_id}    ${col_name}
    Log    ${col_value}    console=True
    Should Be Equal As Strings    ${col_value}    ${exp_col_value}


Run Keywords And Continue On Failure
    [Documentation]    Create a list with the keyword and arguments pair
    ...                    > ${k}=    Create List    <Keyword>    <Argument1>    <Argument2>
    ...                    > ${k}=    Create List    Log To Console    Hello World
    ...                    > ${k2}=    Create List    Capture Page Screenshot
    ...                Create a another list that contains the list of keyword-arguments
    ...                    > ${ks}=    Create List    ${k}    ${k2}
    ...                Run this keyword as: Run Keywords And Continue On Failure    @{ks}
    [Arguments]    @{keywords}

    Should Be List  ${keywords}
    ${kwargs_strings}=    Create List
    ${len}=    Get Length    ${keywords}
    FOR    ${i}    IN RANGE    0    ${len}
        ${k}=    Set Variable    ${keywords[${i}]}
        Should Be List    ${keywords[${i}]}
        ${kwargs}=    Create List    Run Keyword And Continue On Failure    @{k}
        Append To List    ${kwargs_strings}    ${kwargs}
    END

    Log    ${kwargs_strings}

    FOR    ${k}    IN    @{kwargs_strings}
        Run Keyword    @{k}
    END


Clear Current Value And Enter New Value To Field
    [Documentation]    Clears the current value in a field and enters in new value. The field identifier should be passed in as input argument along with the new value.
    [Arguments]    ${identifier}    ${value}

    Clear Element Text    ${identifier}
    Input Text    ${identifier}    ${value}

