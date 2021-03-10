*** Settings ***
Resource    common_variables.resource

*** Variables ***
${APPIAN_LOADER}    xpath=//div[@id='appian-nprogress-parent']
${SIGN_IN_BUTTON}    xpath=//input[@value='Sign In']
${USER_OPTION_MENU}    xpath=//span[contains(@style,'background-image')]
${SIGN_OUT_BUTTON}    xpath=//*[text()='Sign Out']

*** Keywords ***
Open iWorks Application
    [Documentation]    Opens the application URL.

    Go To    ${APPIAN_SERVER}
    Run Keyword And Ignore Error    Alert Should Not Be Present
    Wait Until Element Is Visible    id=un    30s
    Log To Console    Application opened: ${APPIAN_SERVER}


Login To iWorks Application
    [Documentation]    Used to login to the application by navigating to the URL and then entering the username and password.
    ...    The username and password values can be passed in as arguments
    [Arguments]    ${username}    ${pwd}

    Log To Console    Logging in to Application...${space}    no_newline=True
    Input Text    id=un    ${username}
    Input Password    id=pw    ${pwd}
    Click Element    ${SIGN_IN_BUTTON}
    Wait Until Element Is Visible    ${USER_OPTION_MENU}    20sec
    Wait For Appian Page To Completely Load
    Log To Console    Done!


Wait For Appian Page To Completely Load
    [Documentation]    Detects any site and wait for page to load completely
    ...                May be unreliable when server is under heavy load
    [Arguments]    ${timer}=${empty}

    ${prev_kw}=    Register Keyword To Run On Failure    NONE
    ${timer}=    Run Keyword If    '${timer}'=="${empty}"    Get Selenium Timeout
    ...                    ELSE    Set Variable    ${timer}

    ${found_site_loader}=    Run Keyword And Return Status    Wait Until Page Contains Element    ${APPIAN_LOADER}    3sec
    Run Keyword If    ${found_site_loader}==${true}    Run Keywords
    ...    Register Keyword To Run On Failure    ${prev_kw}    AND
    ...    Run Keyword And Continue On Failure    Wait Until Element Is Not Visible    ${APPIAN_LOADER}    ${timer}    AND
    ...    Wait Until Page Does Not Contain Element    ${APPIAN_LOADER}    ${timer}    Site Page failed to load after ${timer}
    Register Keyword To Run On Failure    ${prev_kw}


Logout From iWorks Application
    [Documentation]    Method to logout from Application

    Log To Console    Logging out from Application...${space}    no_newline=True
    Wait Until Element Is Visible    ${USER_OPTION_MENU}    5sec
    Click Element    ${USER_OPTION_MENU}
    Wait Until Element Is Visible    ${SIGN_OUT_BUTTON}    5sec
    Click Element    ${SIGN_OUT_BUTTON}
    Run Keyword And Ignore Error    Alert Should Not Be Present    timeout=3 s
    Wait Until Element Is Visible    ${SIGN_IN_BUTTON}
    Log To Console    Done!