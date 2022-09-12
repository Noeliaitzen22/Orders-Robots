*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Word.Application
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      5x
${GLOBAL_RETRY_INTERVAL}    0.5s


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    # Download the CSV file
    ${userInputUrl}=    Collect CSV file from the user
    Open the robot order website
    ${orders}=    Get Orders    ${userInputUrl}
    #Fill the form using the data from the Csv file
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form for robot    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close browser


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser    ${secret}[url]    maximized=True

Collect CSV file from the user
    Add heading    Url of the CSV file
    Add text input    FileUrl
    ...    label=Insert the CSV file Url
    ${response}=    Run dialog
    RETURN    ${response.FileUrl}

    # Url: https://robotsparebinindustries.com/orders.csv

Get Orders
    [Arguments]    ${userInputUrl}
    Download    ${userInputUrl}    overwrite=True
    ${data}=    Read table from CSV    orders.csv    header=True
    RETURN    ${data}

Fill the form for robot
    [Arguments]    ${row}
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    id:address
    Select From List By Value    head    ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    ${input_legs}=    Set Variable    xpath://input[contains(@id,'16')]
    Input Text    ${input_legs}    ${row}[Legs]
    Input Text    address    ${row}[Address]

Close the annoying modal
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    xpath=(//button[@class="btn btn-dark"])
    Click Element    xpath=(//button[@class="btn btn-dark"])

Preview the robot
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    //button[@id="preview"]
    Click Element    //button[@id="preview"]

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    //button[@id="order"]
    FOR    ${i}    IN RANGE    5
        Click Button    id:order
        # Checking if submit is Ok!
        ${submit_Ok}=    Does Page Contain    Receipt
        IF    ${submit_Ok}    BREAK
    END

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}directorio${/}receipt-${row}[Order number].pdf
    RETURN    ${OUTPUT_DIR}${/}directorio${/}receipt-${row}[Order number].pdf

 Go to order another robot
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Wait Until Page Contains Element    //button[@id="order-another"]
    Click Element    //button[@id="order-another"]

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Page Contains Element    id:robot-preview-image
    Wait Until Element Is Visible    xpath://img[contains(@alt,'Head')]
    Wait Until Element Is Visible    xpath://img[contains(@alt,'Body')]
    Wait Until Element Is Visible    xpath://img[contains(@alt,'Legs')]
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}directorio${/}receipt-screenshot-${row}[Order number].png
    RETURN    ${OUTPUT_DIR}${/}directorio${/}receipt-screenshot-${row}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}:align=center
    # Add Files To Pdf    ${files}    ${pdf}    # ${OUTPUT_DIR}${/}directorio${/}receipt-${row}[Order number].pdf
    Add Watermark Image To PDF
    ...    source_path=${pdf}
    ...    image_path=${screenshot}
    ...    output_path=${pdf}
    Remove File    ${screenshot}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}directorio    ${OUTPUT_DIR}${/}dir-zip.zip
    RPA.FileSystem.Remove Directory    ${OUTPUT_DIR}${/}directorio    recursive=true
