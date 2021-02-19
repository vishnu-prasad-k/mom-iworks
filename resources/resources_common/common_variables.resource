*** Settings ***
Library    OperatingSystem
Library    FakerLibrary
Library    String
Library    SeleniumLibrary
Library    common_custom_keywords.py
Resource    common_utils.resource

*** Variables ***
#####     SELENIUM VARIABLES     #####
${SELENIUM_TIMEOUT}    3 minutes

#####     TEST SUITE VARIABLES     #####
${IS_PREV_TEST_CRIT}          ${true}
${PREV_CRIT_TEST_STATUS}      ${empty}
${NON_CRIT}          non_critical_test
${APPIAN_SERVER}    https://cognizant-82015.appiancloud.com/suite/
${FILE_PATH}    upload

# Employee Creds
${USERNAME_EMPLOYEE}    iw_employee1
${PASSWORD_EMPLOYEE}    Appian@123

# Employer Creds
${USERNAME_EMPLOYER}    iw_employer1
${PASSWORD_EMPLOYER}    Appian@123

# Mediator Creds
${USERNAME_MEDIATOR}    iw_mediator
${PASSWORD_MEDIATOR}    Appian123

*** Keywords ***
Initialise Global Valid File List
    [Documentation]    Initialises the list of Valid files and file count to be used for document selection for uploads.

    @{files} =    List Files In Directory    ${FILE_PATH}    *.*
    Log    ${files}
    ${files_count}=    Get Length    ${files}
    ${files_count}=    Evaluate    ${files_count}-1
    Set Global Variable    @{FILES_TO_UPLOAD}    @{files}
    Set Global Variable    ${FILES_TO_UPLOAD_COUNT}    ${files_count}


Initialise Random Files To Upload List
    [Documentation]    Initialises a random list of Valid files for uploads - items inside the list should be unique.
    [Arguments]    ${num_of_attachments}=1

    ${count}=    Get Length    ${FILES_TO_UPLOAD}
    ${count}=    Convert to Integer    ${count}
    ${random_index}=    FakerLibrary.Random Int    min=0    max=${count-1}
    @{attachment_list}=    Create List

    FOR    ${index}    IN RANGE    0    ${num_of_attachments}
        ${upload_file}=    Set Variable    @{FILES_TO_UPLOAD}[${random_index}]
        ${random_index}=   Evaluate     (${random_index+1})%${count}
        Append To List    ${attachment_list}    ${upload_file}
    END
    Sort List    ${attachment_list}

    [Return]    ${attachment_list}


Initialise Application Contact Details Variables
    [Documentation]    Used to Initialise Application Contact Details Variables used in most ROR forms.
    ...                Default will use Company Profile Registered address and Same as Main Contact (letter of offeree).
    [Arguments]    ${random_mailing_address}=no    ${random_letter_of_offer_addressee}=no

    Log To Console    \########## APPLICATION CONTACT VARIABLES \###########
    #### MAIN CONTACT PERSON ####
    ${CONTACT_DETAILS_MAIN_CONTACT_NAME}=    FakerLibrary.Name
    ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}=    FakerLibrary.Job
    ${CONTACT_DETAILS_MAIN_CONTACT_NUMBER}=    FakerLibrary.Random Int    min=80000000    max=99999999
    ${CONTACT_DETAILS_MAIN_CONTACT_EMAIL}=    Set Variable      bgp.robot@gmail.com
    ${CONTACT_DETAILS_MAIN_CONTACT_ALT_EMAIL}=    Set Variable      bgp.robot+alt_email@gmail.com

    Set Suite Variable    ${CONTACT_DETAILS_MAIN_CONTACT_NAME}
    Set Suite Variable    ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}
    Set Suite Variable    ${CONTACT_DETAILS_MAIN_CONTACT_NUMBER}
    Set Suite Variable    ${CONTACT_DETAILS_MAIN_CONTACT_EMAIL}
    Set Suite Variable    ${CONTACT_DETAILS_MAIN_CONTACT_ALT_EMAIL}

    #### MAILING ADDRESS ####
    ${CONTACT_DETAILS_SAME_AS_REGISTERED_ADDRESS_CHECK}=     Run Keyword If    '${random_mailing_address}'=='Randomly'    Get Random True or False Value
    ...    ELSE    Set Variable    true
    Set Suite Variable    ${CONTACT_DETAILS_SAME_AS_REGISTERED_ADDRESS_CHECK}

    ${addr}=    Run Keyword If    '${CONTACT_DETAILS_SAME_AS_REGISTERED_ADDRESS_CHECK}'=='true'
    ...    Fetch Company Profile Details Via API    data    company    registered_address
    ...    ELSE    Set Variable    ${empty}
    @{addr}=    Run Keyword If    "${addr}"!='${empty}'
    ...    Parse JSON Address    ${addr}
    ...    ELSE    Get Random Valid Address

    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_BUILDING_NAME}    ${addr[0]}
    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_BLOCK}    ${addr[1]}
    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_STREET}    ${addr[2]}
    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_LEVEL}    ${addr[3]}
    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_UNIT}    ${addr[4]}
    Set Suite Variable    ${CONTACT_DETAILS_MAILING_ADDRESS_POSTAL_CODE}    ${addr[5]}

    #### LETTER OF OFFER ADDRESSEE ####
    ${CONTACT_DETAILS_SAME_AS_MAIN_CONTACT_CHECK}=     Run Keyword If    '${random_letter_of_offer_addressee}'=='Randomly'    Get Random True or False Value
    ...    ELSE    Set Variable    true
    Set Suite Variable    ${CONTACT_DETAILS_SAME_AS_MAIN_CONTACT_CHECK}

    ${lof_name}=    FakerLibrary.Name
    ${lof_job_title}=   FakerLibrary.Job
    Run Keyword If    '${CONTACT_DETAILS_SAME_AS_MAIN_CONTACT_CHECK}'=='true'    Run Keywords
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_NAME}    ${CONTACT_DETAILS_MAIN_CONTACT_NAME}    AND
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}    ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}    AND
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_EMAIL}    ${CONTACT_DETAILS_MAIN_CONTACT_EMAIL}
        ...    ELSE    Run Keywords
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_NAME}    ${lof_name}    AND
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}    ${lof_job_title}    AND
        ...    Set Suite Variable    ${CONTACT_DETAILS_LOF_CONTACT_EMAIL}    bgp.robot+lof@gmail.com

    #### LOGS ####
    ${main_contact}=    Catenate    SEPARATOR=\n    --- Main Contact Person Details ---
    ...    | Name: ${CONTACT_DETAILS_MAIN_CONTACT_NAME}
    ...    | Job Title: ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE} | Contact: ${CONTACT_DETAILS_MAIN_CONTACT_NUMBER}
    ...    | Email: ${CONTACT_DETAILS_MAIN_CONTACT_EMAIL} | Email (Alt): ${CONTACT_DETAILS_MAIN_CONTACT_ALT_EMAIL}

    ${mailing_addr}=    Catenate    SEPARATOR=\n    --- Mailing Address Details ---
    ...    | Building Name: ${CONTACT_DETAILS_MAILING_ADDRESS_BUILDING_NAME}
    ...    | Block: ${CONTACT_DETAILS_MAILING_ADDRESS_BLOCK} | Street: ${CONTACT_DETAILS_MAILING_ADDRESS_STREET}
    ...    | Level: ${CONTACT_DETAILS_MAILING_ADDRESS_LEVEL} | Unit: ${CONTACT_DETAILS_MAILING_ADDRESS_UNIT}
    ...    | Postal: ${CONTACT_DETAILS_MAILING_ADDRESS_POSTAL_CODE}
    ...    | Same as registered address in Company Profile: ${CONTACT_DETAILS_SAME_AS_REGISTERED_ADDRESS_CHECK}

    ${lof_addressee}=    Catenate    SEPARATOR=\n    --- Letter Of Offer Addressee Details ---
    ...    | Name: ${CONTACT_DETAILS_LOF_CONTACT_NAME}
    ...    | Job Title: ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}
    ...    | Email: ${CONTACT_DETAILS_LOF_CONTACT_EMAIL}
    ...    | Same as Main Contact Person: ${CONTACT_DETAILS_SAME_AS_MAIN_CONTACT_CHECK}
    Log    ${main_contact}\n${mailing_addr}\n${lof_addressee}    console=True

    # This will be used later to compare with PDF data generated in Appian
    ${contact_details_main_dict}=    Create Dictionary
    @{contact_details_main_list}=    Create List
    ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}=    Replace String    ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}    ,    ${EMPTY}
    Append To List    ${contact_details_main_list}     Name ${CONTACT_DETAILS_MAIN_CONTACT_NAME}    Job Title ${CONTACT_DETAILS_MAIN_CONTACT_JOB_TITLE}    Contact No ${CONTACT_DETAILS_MAIN_CONTACT_NUMBER}    Email ${CONTACT_DETAILS_MAIN_CONTACT_EMAIL}    Alternate Contact Person's Email ${CONTACT_DETAILS_MAIN_CONTACT_ALT_EMAIL}
    Set To Dictionary    ${contact_details_main_dict}    Main Contact Person    ${contact_details_main_list}
    Set Suite Variable    ${CONTACT_DETAILS_MAIN_DICT}    ${contact_details_main_dict}

    ${contact_details_lof_dict}=    Create Dictionary
    @{contact_details_lof_list}=    Create List
    ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}=    Replace String    ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}    ,    ${EMPTY}
    Append To List    ${contact_details_lof_list}     Name ${CONTACT_DETAILS_LOF_CONTACT_NAME}    Job Title ${CONTACT_DETAILS_LOF_CONTACT_JOB_TITLE}    Email ${CONTACT_DETAILS_LOF_CONTACT_EMAIL}
    Set To Dictionary    ${contact_details_lof_dict}    Letter Of Offer Addressee    ${contact_details_lof_list}
    Set Suite Variable    ${CONTACT_DETAILS_LOF_DICT}    ${contact_details_lof_dict}

