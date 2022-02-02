*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Desktop
Library           RPA.Tables
Library           RPA.Dialogs
Library           RPA.PDF
Library           RPA.Archive

*** Variables ***
# ${URL}=         https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMOUNT}=    100x
${GLOBAL_RETRY_INTERVAL}=    0.5 sec

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Input Form Dialog OR access vault
    Open the robot order website    ${url}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Input Form Dialog OR access vault
    # Add heading    Input Required
    # Add text input    url    label=URL
    # ${result}=    Run dialog
    # [Return]    ${result.url}
    ${secret}=    Get Secret    credentials
    Log    ${secret}
    [Return]    ${secret}

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    Download the Excel file
    # Open File    orders.csv
    ${orders}=    Read table from CSV    orders.csv    header=True
    Close Workbook
    [Return]    ${orders}

Close the annoying modal
    # @{res} = "1"    #Does Page Contain Checkbox    css:div.modal-body
    # IF    ${res} == "1"
    Click Element If Visible    css:button.btn.btn-danger
    #    ${res} = "0"
    # END

Fill the form
    [Arguments]    ${row}
    Select From List By Index    css:select#head.custom-select    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    css:input[placeholder="Shipping address"]    ${row}[Address]

Preview the robot
    Click Button    css:button#preview.btn.btn-secondary

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Click Button    css:button#order.btn.btn-primary
    ${res} =    Is Element Visible    css:div.alert.alert-danger
    IF    ${res} == ${True}
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click Button    css:button#order.btn.btn-primary
    END

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdf}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_num}.pdf
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_num}.pdf
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Set Local Variable    ${screenshot}    ${OUTPUT_DIR}${/}receipts${/}screenshot_${order_num}.png
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}screenshot_${order_num}.png
    [Return]    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${image_file} =    Create List    ${screenshot}:align=centers
    Add Files To Pdf    ${image_file}    ${pdf}    append=True
    Close Pdf    ${pdf}

Go to order another robot
    Click Button    css:button#order-another.btn.btn-primary
    Wait Until Element Is Visible    css:button#order.btn.btn-primary

Create a ZIP file of the receipts
    ${zip_file} =    Set Variable    ${OUTPUT_DIR}${/}all_recripts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts${/}    ${zip_file}
