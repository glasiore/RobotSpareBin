*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${TRUE}
Library             RPA.Dialogs
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Tasks
Library             RPA.FileSystem
Library             RPA.Archive
Library             Collections
Library             RPA.Robocorp.Vault


*** Tasks ***
Open the robot order website of RobotSpareBin
    ${StoreURLName}=    Get Secret    StoreURLName
    ${FileURL}=    User Dialog for File
    Open the robot order website    ${StoreURLName}[StoreUrlKey]
    ${orders}=    Get orders    ${FileURL}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    [Arguments]    ${StoreURLName}
    Open Available Browser    ${StoreURLName}    maximized= True
    Wait Until Element Is Visible    css:.btn-dark

User Dialog for File
    Add heading    Please add CSV file link here
    Add text input
    ...    csvlink
    ...    label=CSV file link
    ...    placeholder=https://robotsparebinindustries.com/orders.csv
    ...    rows=3
    ${result}=    Run dialog
    RETURN    ${result.csvlink}

Get orders
    [Arguments]    ${FileURL}
    Download    ${FileURL}    overwrite= True
    ${table}=    Read table from CSV    orders.csv    header= ${True}
    RETURN    ${table}

Close the annoying modal
    Click Button    css:.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    #${legid}=    Get Element Attribute    //*[text()= "3. Legs:"]    for
    #Input Text    id:${legid}    ${order}[Legs]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    ${orderRetryCount}=    Set Variable    ${0}
    WHILE    ${orderRetryCount} < ${10}
        Click Button    id:order
        Sleep    2s
        ${orderCondition}=    Does Page Contain Button    id:order-another
        IF    ${orderCondition} == ${True}
            BREAK
        ELSE
            ${orderRetryCount}=    Set Variable    ${orderRetryCount + 1}
        END
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    ${receipt_outerHTML}=    Get Element Attribute    id:order-completion    outerHTML
    ${pdfPath}=    Set Variable    ${OUTPUT_DIR}${/}Receipts${/}Receipt_${orderNumber}.pdf
    Html To Pdf    ${receipt_outerHTML}    ${pdfPath}
    RETURN    ${pdfPath}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    ${screenshot}=    Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}Receipts${/}Receipt_Image_${orderNumber}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${orderNumber}
    Open Pdf    ${OUTPUT_DIR}${/}Receipts${/}Receipt_${orderNumber}.pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}Receipts${/}Receipt_Image_${orderNumber}.png
    ...    ${OUTPUT_DIR}${/}Receipts${/}Receipt_${orderNumber}.pdf
    Remove File    ${OUTPUT_DIR}${/}Receipts${/}Receipt_Image_${orderNumber}.png
    Close All Pdfs

Go to order another robot
    Click Button When Visible    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${OUTPUT_DIR}${/}ReceiptsZip.zip    include=*.pdf
    Remove Directory    ${OUTPUT_DIR}${/}Receipts    recursive=${True}
