param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$AdminEmail = "admin@librosphere.local",
    [string]$AdminPassword = "Admin123!",
    [string]$UserEmail = "user@librosphere.local",
    [string]$UserPassword = "User123!",
    [switch]$SkipSeedEndpoints,
    [switch]$SkipStripeSteps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

$script:Results = New-Object System.Collections.Generic.List[object]
$script:RunSuffix = Get-Date -Format "yyyyMMddHHmmss"

function Add-Result {
    param(
        [string]$Step,
        [string]$Status,
        [string]$Details = ""
    )

    $script:Results.Add([pscustomobject]@{
        Step = $Step
        Status = $Status
        Details = $Details
    }) | Out-Null

    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "Yellow" }
    }

    Write-Host ("[{0}] {1}" -f $Status, $Step) -ForegroundColor $color
    if ($Details) {
        Write-Host ("       {0}" -f $Details)
    }
}

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties | Where-Object {
            $_.Name.Equals($name, [System.StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -First 1

        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function Get-FirstItem {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $items = @($Value)
    if ($items.Count -eq 0) {
        return $null
    }

    return $items[0]
}

function New-HttpMethod {
    param([string]$Method)

    switch ($Method.ToUpperInvariant()) {
        "GET" { return [System.Net.Http.HttpMethod]::Get }
        "POST" { return [System.Net.Http.HttpMethod]::Post }
        "PUT" { return [System.Net.Http.HttpMethod]::Put }
        "DELETE" { return [System.Net.Http.HttpMethod]::Delete }
        default { return [System.Net.Http.HttpMethod]::new($Method.ToUpperInvariant()) }
    }
}

function Invoke-Api {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Token,
        [object]$Body,
        [hashtable]$FormFields,
        [int[]]$ExpectedStatusCodes = @(200)
    )

    $uri = [System.Uri]::new(("{0}{1}" -f $BaseUrl.TrimEnd("/"), $Path))
    $request = [System.Net.Http.HttpRequestMessage]::new((New-HttpMethod $Method), $uri)

    if ($Token) {
        $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $Token)
    }

    if ($null -ne $FormFields) {
        $content = [System.Net.Http.MultipartFormDataContent]::new()

        foreach ($entry in $FormFields.GetEnumerator()) {
            $key = [string]$entry.Key
            $value = $entry.Value

            if ($null -eq $value) {
                continue
            }

            if ($value -is [string] -or $value -isnot [System.Collections.IEnumerable]) {
                $content.Add([System.Net.Http.StringContent]::new([string]$value), $key)
                continue
            }

            foreach ($item in @($value)) {
                if ($null -ne $item) {
                    $content.Add([System.Net.Http.StringContent]::new([string]$item), $key)
                }
            }
        }

        $request.Content = $content
    }
    elseif ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Depth 20
        $request.Content = [System.Net.Http.StringContent]::new(
            $json,
            [System.Text.Encoding]::UTF8,
            "application/json")
    }

    $response = $script:HttpClient.SendAsync($request).GetAwaiter().GetResult()
    $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $statusCode = [int]$response.StatusCode

    if ($ExpectedStatusCodes -notcontains $statusCode) {
        throw "Unexpected status code $statusCode for $Method $Path. Body: $text"
    }

    $json = $null
    if (-not [string]::IsNullOrWhiteSpace($text)) {
        try {
            $json = $text | ConvertFrom-Json
        }
        catch {
            $json = $null
        }
    }

    return [pscustomobject]@{
        StatusCode = $statusCode
        Json = $json
        Text = $text
        Headers = $response.Headers
        ContentHeaders = $response.Content.Headers
    }
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    try {
        $result = & $Action
        Add-Result -Step $Name -Status "PASS"
        return $result
    }
    catch {
        Add-Result -Step $Name -Status "FAIL" -Details $_.Exception.Message
        return $null
    }
}

function Skip-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    Add-Result -Step $Name -Status "SKIP" -Details $Reason
}

function Require-Value {
    param(
        [object]$Value,
        [string]$Message
    )

    if ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value))) {
        throw $Message
    }

    return $Value
}

function Wait-ForApi {
    $lastError = $null

    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            Invoke-Api -Method GET -Path "/api/payment/config" -ExpectedStatusCodes @(200) | Out-Null
            return
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 2
        }
    }

    throw "API did not become ready at $BaseUrl. Last error: $lastError"
}

function Wait-ForLibraryAccess {
    param(
        [string]$Token,
        [string]$BookId
    )

    $lastError = $null

    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            return Invoke-Api -Method GET -Path "/api/library/$BookId/read" -Token $Token -ExpectedStatusCodes @(200)
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 2
        }
    }

    throw "Library read link was not available in time. Last error: $lastError"
}

function Wait-ForLibraryForbidden {
    param(
        [string]$Token,
        [string]$BookId
    )

    $lastError = $null

    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            return Invoke-Api -Method GET -Path "/api/library/$BookId/read" -Token $Token -ExpectedStatusCodes @(403)
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 2
        }
    }

    throw "Library read endpoint did not return the expected pending-payment 403 in time. Last error: $lastError"
}

$script:HttpClient = [System.Net.Http.HttpClient]::new()
$script:HttpClient.Timeout = [TimeSpan]::FromSeconds(90)

try {
    $null = Invoke-Step -Name "API readiness check" -Action { Wait-ForApi }

    $paymentConfig = Invoke-Step -Name "GET /api/payment/config" -Action {
        Invoke-Api -Method GET -Path "/api/payment/config" -ExpectedStatusCodes @(200)
    }

    $adminLogin = Invoke-Step -Name "POST /api/auth/login (admin)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/login" -Body @{
            email = $AdminEmail
            password = $AdminPassword
        } -ExpectedStatusCodes @(200)
    }

    $adminAccessToken = Get-PropertyValue $adminLogin.Json @("AccessToken")
    $adminRefreshToken = Get-PropertyValue $adminLogin.Json @("RefreshToken")

    $userLogin = Invoke-Step -Name "POST /api/auth/login (user)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/login" -Body @{
            email = $UserEmail
            password = $UserPassword
        } -ExpectedStatusCodes @(200)
    }

    $userAccessToken = Get-PropertyValue $userLogin.Json @("AccessToken")
    $userRefreshToken = Get-PropertyValue $userLogin.Json @("RefreshToken")

    $null = Invoke-Step -Name "POST /api/auth/refresh (admin)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/refresh" -Body @{
            refreshToken = (Require-Value $adminRefreshToken "Missing admin refresh token.")
        } -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "POST /api/auth/refresh (user)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/refresh" -Body @{
            refreshToken = (Require-Value $userRefreshToken "Missing user refresh token.")
        } -ExpectedStatusCodes @(200)
    }

    $adminMe = Invoke-Step -Name "GET /api/user/me (admin)" -Action {
        Invoke-Api -Method GET -Path "/api/user/me" -Token (Require-Value $adminAccessToken "Missing admin access token.") -ExpectedStatusCodes @(200)
    }

    $userMe = Invoke-Step -Name "GET /api/user/me (user)" -Action {
        Invoke-Api -Method GET -Path "/api/user/me" -Token (Require-Value $userAccessToken "Missing user access token.") -ExpectedStatusCodes @(200)
    }

    $userId = Get-PropertyValue $userMe.Json @("Id")
    $null = Require-Value $userId "Could not resolve seeded user id."

    $tempEmail = "smoke+$script:RunSuffix@librosphere.local"
    $tempPassword = "Smoke123!"

    $registerResponse = Invoke-Step -Name "POST /api/auth/register" -Action {
        Invoke-Api -Method POST -Path "/api/auth/register" -Body @{
            firstName = "Smoke"
            lastName = "Runner"
            email = $tempEmail
            password = $tempPassword
        } -ExpectedStatusCodes @(200)
    }

    $tempAccessToken = Get-PropertyValue $registerResponse.Json @("AccessToken")
    $tempMe = Invoke-Step -Name "GET /api/user/me (temp user)" -Action {
        Invoke-Api -Method GET -Path "/api/user/me" -Token (Require-Value $tempAccessToken "Missing temp user access token.") -ExpectedStatusCodes @(200)
    }

    $tempUserId = Get-PropertyValue $tempMe.Json @("Id")
    $null = Invoke-Step -Name "GET /api/user/{id} (temp user via admin)" -Action {
        Invoke-Api -Method GET -Path "/api/user/$tempUserId" -Token $adminAccessToken -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "GET /api/user (admin list)" -Action {
        Invoke-Api -Method GET -Path "/api/user?page=1&pageSize=10" -Token $adminAccessToken -ExpectedStatusCodes @(200)
    }

    if ($SkipSeedEndpoints) {
        Skip-Step -Name "POST /api/seed/genres" -Reason "Skipped by flag."
        Skip-Step -Name "POST /api/seed/catalog" -Reason "Skipped by flag."
    }
    else {
        $null = Invoke-Step -Name "POST /api/seed/genres" -Action {
            Invoke-Api -Method POST -Path "/api/seed/genres" -Token $adminAccessToken -ExpectedStatusCodes @(200)
        }

        $null = Invoke-Step -Name "POST /api/seed/catalog" -Action {
            Invoke-Api -Method POST -Path "/api/seed/catalog" -Token $adminAccessToken -ExpectedStatusCodes @(200)
        }
    }

    $genresList = Invoke-Step -Name "GET /api/genre" -Action {
        Invoke-Api -Method GET -Path "/api/genre?page=1&pageSize=20" -ExpectedStatusCodes @(200)
    }

    $authorsList = Invoke-Step -Name "GET /api/author" -Action {
        Invoke-Api -Method GET -Path "/api/author?page=1&pageSize=20" -ExpectedStatusCodes @(200)
    }

    $booksList = Invoke-Step -Name "GET /api/book" -Action {
        Invoke-Api -Method GET -Path "/api/book?page=1&pageSize=20" -ExpectedStatusCodes @(200)
    }

    $catalogBook = Get-FirstItem (Get-PropertyValue $booksList.Json @("Items"))
    $catalogBookId = Get-PropertyValue $catalogBook @("BookId", "bookId")
    $catalogBookAmount = [decimal](Require-Value (Get-PropertyValue $catalogBook @("Amount", "amount")) "Catalog book amount is missing.")
    $catalogBookCurrency = [string](Require-Value (Get-PropertyValue $catalogBook @("Currency", "currency")) "Catalog book currency is missing.")
    $null = Require-Value $catalogBookId "No catalog book available for smoke flow."

    $null = Invoke-Step -Name "GET /api/book/{id}" -Action {
        Invoke-Api -Method GET -Path "/api/book/$catalogBookId" -ExpectedStatusCodes @(200)
    }

    $catalogGenre = Get-FirstItem (Get-PropertyValue $genresList.Json @("Items"))
    $catalogAuthor = Get-FirstItem (Get-PropertyValue $authorsList.Json @("Items"))
    $null = Require-Value $catalogGenre "No genre available."
    $null = Require-Value $catalogAuthor "No author available."

    $tempGenreName = "Smoke Genre $script:RunSuffix"
    $tempGenreCreate = Invoke-Step -Name "POST /api/genre" -Action {
        Invoke-Api -Method POST -Path "/api/genre" -Token $adminAccessToken -Body @{
            name = $tempGenreName
        } -ExpectedStatusCodes @(201)
    }

    $tempGenreId = [string](Require-Value $tempGenreCreate.Text "Genre id was not returned.")
    $tempGenreId = $tempGenreId.Trim('"')

    $null = Invoke-Step -Name "GET /api/genre/{id}" -Action {
        Invoke-Api -Method GET -Path "/api/genre/$tempGenreId" -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "PUT /api/genre/{id}" -Action {
        Invoke-Api -Method PUT -Path "/api/genre/$tempGenreId" -Token $adminAccessToken -Body @{
            name = "$tempGenreName Updated"
        } -ExpectedStatusCodes @(204)
    }

    $tempAuthorName = "Smoke Author $script:RunSuffix"
    $tempAuthorCreate = Invoke-Step -Name "POST /api/author" -Action {
        Invoke-Api -Method POST -Path "/api/author" -Token $adminAccessToken -Body @{
            name = $tempAuthorName
            biography = "Smoke test author biography."
        } -ExpectedStatusCodes @(201)
    }

    $tempAuthorId = [string](Require-Value $tempAuthorCreate.Text "Author id was not returned.")
    $tempAuthorId = $tempAuthorId.Trim('"')

    $null = Invoke-Step -Name "GET /api/author/{id}" -Action {
        Invoke-Api -Method GET -Path "/api/author/$tempAuthorId" -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "PUT /api/author/{id}" -Action {
        Invoke-Api -Method PUT -Path "/api/author/$tempAuthorId" -Token $adminAccessToken -Body @{
            name = "$tempAuthorName Updated"
            biography = "Updated smoke test author biography."
        } -ExpectedStatusCodes @(204)
    }

    $tempBookTitle = "Smoke Book $script:RunSuffix"
    $tempBookCreate = Invoke-Step -Name "POST /api/book" -Action {
        Invoke-Api -Method POST -Path "/api/book" -Token $adminAccessToken -FormFields @{
            Title = $tempBookTitle
            Description = "Smoke test book description."
            PriceAmount = "19.99"
            CurrencyCode = "USD"
            PdfLink = "https://example.com/smoke-book.pdf"
            ImageLink = "https://example.com/smoke-book.jpg"
            AuthorId = $tempAuthorId
            GenreIds = @($tempGenreId)
        } -ExpectedStatusCodes @(201)
    }

    $tempBookId = [string](Require-Value (Get-PropertyValue $tempBookCreate.Json @("BookId")) "Book id was not returned.")

    $null = Invoke-Step -Name "GET /api/book/{id} (temp book)" -Action {
        Invoke-Api -Method GET -Path "/api/book/$tempBookId" -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "GET /api/book/{id}/assets" -Action {
        Invoke-Api -Method GET -Path "/api/book/$tempBookId/assets" -Token $adminAccessToken -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "PUT /api/book/{id}" -Action {
        Invoke-Api -Method PUT -Path "/api/book/$tempBookId" -Token $adminAccessToken -FormFields @{
            Title = "$tempBookTitle Updated"
            Description = "Updated smoke test book description."
            PriceAmount = "21.50"
            CurrencyCode = "USD"
            PdfLink = "https://example.com/smoke-book-updated.pdf"
            ImageLink = "https://example.com/smoke-book-updated.jpg"
            AuthorId = $tempAuthorId
            GenreIds = @($tempGenreId)
        } -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "GET /api/reviews/book/{bookId}" -Action {
        Invoke-Api -Method GET -Path "/api/reviews/book/$($catalogBookId)?page=1&pageSize=10" -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "POST /api/wishlist" -Action {
        Invoke-Api -Method POST -Path "/api/wishlist" -Token $userAccessToken -Body @{
            bookId = $catalogBookId
        } -ExpectedStatusCodes @(204)
    }

    $null = Invoke-Step -Name "GET /api/wishlist" -Action {
        Invoke-Api -Method GET -Path "/api/wishlist" -Token $userAccessToken -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "DELETE /api/wishlist/{bookId}" -Action {
        Invoke-Api -Method DELETE -Path "/api/wishlist/$catalogBookId" -Token $userAccessToken -ExpectedStatusCodes @(204)
    }

    $cartIdForOrder = [guid]::NewGuid().ToString()
    $null = Invoke-Step -Name "POST /api/cart (order cart)" -Action {
        Invoke-Api -Method POST -Path "/api/cart" -Token $userAccessToken -Body @{
            id = $cartIdForOrder
            userId = $userId
            clientSecret = $null
            paymentIntentId = $null
            items = @(
                @{
                    bookId = $catalogBookId
                    price = @{
                        amount = $catalogBookAmount
                        currencyCode = $catalogBookCurrency
                    }
                }
            )
        } -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "GET /api/cart/{id}" -Action {
        Invoke-Api -Method GET -Path "/api/cart/$cartIdForOrder" -Token $userAccessToken -ExpectedStatusCodes @(200)
    }

    if ($SkipStripeSteps) {
        Skip-Step -Name "POST /api/payment/{cartId}" -Reason "Skipped by flag."
        Skip-Step -Name "POST /api/orders" -Reason "Skipped because payment step was skipped."
        Skip-Step -Name "GET /api/orders" -Reason "Skipped because order was not created."
        Skip-Step -Name "GET /api/orders/{id}" -Reason "Skipped because order was not created."
        Skip-Step -Name "GET /api/library" -Reason "Skipped because order was not created."
        Skip-Step -Name "GET /api/library/{bookId}/read" -Reason "Skipped because order was not created."
        Skip-Step -Name "POST /api/payment/webhook" -Reason "Skipped by flag."
    }
    else {
        $null = Invoke-Step -Name "POST /api/payment/{cartId}" -Action {
            Invoke-Api -Method POST -Path "/api/payment/$cartIdForOrder" -Token $userAccessToken -ExpectedStatusCodes @(200)
        }

        $orderCreate = Invoke-Step -Name "POST /api/orders" -Action {
            Invoke-Api -Method POST -Path "/api/orders" -Token $userAccessToken -Body @{
                cartId = $cartIdForOrder
            } -ExpectedStatusCodes @(201)
        }

        $orderId = $null
        if ($null -ne $orderCreate -and $null -ne $orderCreate.Json) {
            $orderId = Get-PropertyValue $orderCreate.Json @("Id")
        }

        $null = Invoke-Step -Name "GET /api/orders" -Action {
            Invoke-Api -Method GET -Path "/api/orders?page=1&pageSize=10" -Token $userAccessToken -ExpectedStatusCodes @(200)
        }

        if ($orderId) {
            $null = Invoke-Step -Name "GET /api/orders/{id}" -Action {
                Invoke-Api -Method GET -Path "/api/orders/$orderId" -Token $userAccessToken -ExpectedStatusCodes @(200)
            }
        }
        else {
            Skip-Step -Name "GET /api/orders/{id}" -Reason "Order id was not returned."
        }

        $null = Invoke-Step -Name "GET /api/library" -Action {
            Invoke-Api -Method GET -Path "/api/library?page=1&pageSize=20" -Token $userAccessToken -ExpectedStatusCodes @(200)
        }

        $null = Invoke-Step -Name "GET /api/library/{bookId}/read (pending payment -> 403)" -Action {
            Wait-ForLibraryForbidden -Token $userAccessToken -BookId $catalogBookId
        }

        $null = Invoke-Step -Name "POST /api/payment/webhook" -Action {
            Invoke-Api -Method POST -Path "/api/payment/webhook" -Body @{
                ping = "smoke"
            } -ExpectedStatusCodes @(400)
        }
    }

    $null = Invoke-Step -Name "GET /api/recommendations" -Action {
        Invoke-Api -Method GET -Path "/api/recommendations?take=5" -Token $userAccessToken -ExpectedStatusCodes @(200)
    }

    $reviewCreate = Invoke-Step -Name "POST /api/reviews" -Action {
        Invoke-Api -Method POST -Path "/api/reviews" -Token $userAccessToken -Body @{
            bookId = $catalogBookId
            rating = 5
            comment = "Smoke test review."
        } -ExpectedStatusCodes @(201)
    }

    $reviewId = $null
    if ($null -ne $reviewCreate) {
        $reviewId = [string]($reviewCreate.Text.Trim('"'))
    }

    $null = Invoke-Step -Name "GET /api/reviews/me" -Action {
        Invoke-Api -Method GET -Path "/api/reviews/me?page=1&pageSize=10" -Token $userAccessToken -ExpectedStatusCodes @(200)
    }

    if ($reviewId) {
        $null = Invoke-Step -Name "GET /api/reviews/{id}" -Action {
            Invoke-Api -Method GET -Path "/api/reviews/$reviewId" -ExpectedStatusCodes @(200)
        }

        $null = Invoke-Step -Name "PUT /api/reviews/{id}" -Action {
            Invoke-Api -Method PUT -Path "/api/reviews/$reviewId" -Token $userAccessToken -Body @{
                rating = 4
                comment = "Updated smoke test review."
            } -ExpectedStatusCodes @(204)
        }

        $null = Invoke-Step -Name "DELETE /api/reviews/{id}" -Action {
            Invoke-Api -Method DELETE -Path "/api/reviews/$reviewId" -Token $userAccessToken -ExpectedStatusCodes @(204)
        }
    }
    else {
        Skip-Step -Name "GET /api/reviews/{id}" -Reason "Review id was not returned."
        Skip-Step -Name "PUT /api/reviews/{id}" -Reason "Review id was not returned."
        Skip-Step -Name "DELETE /api/reviews/{id}" -Reason "Review id was not returned."
    }

    $cartIdForDelete = [guid]::NewGuid().ToString()
    $null = Invoke-Step -Name "POST /api/cart (delete cart)" -Action {
        Invoke-Api -Method POST -Path "/api/cart" -Token $userAccessToken -Body @{
            id = $cartIdForDelete
            userId = $userId
            clientSecret = $null
            paymentIntentId = $null
            items = @(
                @{
                    bookId = $catalogBookId
                    price = @{
                        amount = $catalogBookAmount
                        currencyCode = $catalogBookCurrency
                    }
                }
            )
        } -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "DELETE /api/cart/{id}" -Action {
        Invoke-Api -Method DELETE -Path "/api/cart/$cartIdForDelete" -Token $userAccessToken -ExpectedStatusCodes @(204)
    }

    $null = Invoke-Step -Name "GET /api/analytics/overview" -Action {
        Invoke-Api -Method GET -Path "/api/analytics/overview?recentActivityTake=10" -Token $adminAccessToken -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "DELETE /api/book/{id}" -Action {
        Invoke-Api -Method DELETE -Path "/api/book/$tempBookId" -Token $adminAccessToken -ExpectedStatusCodes @(204)
    }

    $null = Invoke-Step -Name "DELETE /api/author/{id}" -Action {
        Invoke-Api -Method DELETE -Path "/api/author/$tempAuthorId" -Token $adminAccessToken -ExpectedStatusCodes @(204)
    }

    $null = Invoke-Step -Name "DELETE /api/genre/{id}" -Action {
        Invoke-Api -Method DELETE -Path "/api/genre/$tempGenreId" -Token $adminAccessToken -ExpectedStatusCodes @(204)
    }

    $null = Invoke-Step -Name "POST /api/auth/logout (temp user)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/logout" -Token $tempAccessToken -ExpectedStatusCodes @(200)
    }

    if ($tempUserId) {
        $null = Invoke-Step -Name "DELETE /api/user/{id}" -Action {
            Invoke-Api -Method DELETE -Path "/api/user/$tempUserId" -Token $adminAccessToken -ExpectedStatusCodes @(204)
        }
    }
    else {
        Skip-Step -Name "DELETE /api/user/{id}" -Reason "Temp user id was not available."
    }

    $null = Invoke-Step -Name "POST /api/auth/logout (user)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/logout" -Token $userAccessToken -ExpectedStatusCodes @(200)
    }

    $null = Invoke-Step -Name "POST /api/auth/logout (admin)" -Action {
        Invoke-Api -Method POST -Path "/api/auth/logout" -Token $adminAccessToken -ExpectedStatusCodes @(200)
    }
}
catch {
    Add-Result -Step "Fatal execution" -Status "FAIL" -Details $_.Exception.Message
}
finally {
    if ($null -ne $script:HttpClient) {
        $script:HttpClient.Dispose()
    }
}

Write-Host ""
Write-Host "Smoke test summary" -ForegroundColor Cyan
$script:Results | Format-Table -AutoSize

$failedCount = @($script:Results | Where-Object { $_.Status -eq "FAIL" }).Count
if ($failedCount -gt 0) {
    exit 1
}

exit 0
