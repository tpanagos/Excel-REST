Attribute VB_Name = "RestRequestSpecs"
''
' RestRequestSpecs
' (c) Tim Hall - https://github.com/timhall/Excel-REST
'
' Specs for the RestRequest class
'
' @author: tim.hall.engr@gmail.com
' @license: MIT (http://www.opensource.org/licenses/mit-license.php)
'
' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ '

Public Function Specs() As SpecSuite
    Set Specs = New SpecSuite
    Dim Request As RestRequest
    Dim Body As Object
    
    Specs.Description = "RestRequest"
    
    With Specs.It("should replace url segments for FormattedResource")
        Set Request = New RestRequest
        
        Request.Resource = "{a1}/{b2}/{c3}/{a1/b2/c3}"
        Request.AddUrlSegment "a1", "A"
        Request.AddUrlSegment "b2", "B"
        Request.AddUrlSegment "c3", "C"
        Request.AddUrlSegment "a1/b2/c3", "D"
        
        .Expect(Request.FormattedResource).ToEqual "A/B/C/D"
    End With
    
    With Specs.It("should only include parameters in querystring for GET requests")
        Set Request = New RestRequest
        
        Request.AddParameter "A", 123
        
        Request.Method = httpGET
        .Expect(Request.FormattedResource).ToEqual "?A=123"
        
        Request.Method = httpPOST
        .Expect(Request.FormattedResource).ToEqual ""
        Request.Method = httpPUT
        .Expect(Request.FormattedResource).ToEqual ""
        Request.Method = httpPATCH
        .Expect(Request.FormattedResource).ToEqual ""
        Request.Method = httpDELETE
        .Expect(Request.FormattedResource).ToEqual ""
    End With
    
    With Specs.It("should include querystring parameters in FormattedResource for all request types")
        Set Request = New RestRequest

        Request.AddQuerystringParam "A", 123
        
        Request.Method = httpGET
        .Expect(Request.FormattedResource).ToEqual "?A=123"
        Request.Method = httpPOST
        .Expect(Request.FormattedResource).ToEqual "?A=123"
        Request.Method = httpPUT
        .Expect(Request.FormattedResource).ToEqual "?A=123"
        Request.Method = httpPATCH
        .Expect(Request.FormattedResource).ToEqual "?A=123"
        Request.Method = httpDELETE
        .Expect(Request.FormattedResource).ToEqual "?A=123"
    End With

    With Specs.It("should have ? and add & between parameters for querystring")
        Set Request = New RestRequest

        Request.AddParameter "A", 123
        Request.AddParameter "B", "456"
        Request.AddQuerystringParam "C", 789
        Request.Method = httpGET
        
        .Expect(Request.FormattedResource).ToEqual "?A=123&B=456&C=789"
    End With
    
    With Specs.It("should not add ? if already in resource")
        Set Request = New RestRequest
        
        Request.AddParameter "B", "456"
        Request.Method = httpGET
        Request.Resource = "?A=123"
        
        .Expect(Request.FormattedResource).ToEqual "?A=123&B=456"
    End With
    
    With Specs.It("should not include http/https if included in resource")
        Set Request = New RestRequest
        
        Request.Resource = "http://localhost:3000/get"
        .Expect(Request.FullUrl("")).ToEqual "http://localhost:3000/get"
        
        Request.Resource = "https://localhost:3000/get"
        .Expect(Request.FullUrl("")).ToEqual "https://localhost:3000/get"
    End With
    
    With Specs.It("should add protocol if none is given or starts with localhost")
        Set Request = New RestRequest
        Request.Resource = "/get"
        .Expect(Request.FullUrl("localhost:3000")).ToEqual "http://localhost:3000/get"
        
        Set Request = New RestRequest
        Request.Resource = "/get"
        Request.RequireHTTPS = True
        .Expect(Request.FullUrl("localhost:3000")).ToEqual "https://localhost:3000/get"
    End With

    With Specs.It("should URL encode querystring")
        Set Request = New RestRequest
    
        Request.AddParameter "A B", " !""#$%&'"
        Request.Method = httpGET
        
        .Expect(Request.FormattedResource).ToEqual "?A+B=+%21%22%23%24%25%26%27"
    End With
    
    With Specs.It("should use body string directly if no parameters")
        Set Request = New RestRequest
        
        Request.AddBodyString "ABC"
        .Expect(Request.Body).ToEqual "ABC"
    End With

    With Specs.It("should only combine body and parameters if not GET Request")
        Set Request = New RestRequest
        
        Set Body = New Dictionary
        Body.Add "A", 123
        
        Request.AddBody Body
        Request.AddParameter "b", 456
        
        Request.Method = httpGET
        .Expect(Request.Body).ToEqual "{""A"":123}"
        
        Request.Method = httpPOST
        .Expect(Request.Body).ToEqual "{""b"":456,""A"":123}"
    End With
    
    With Specs.It("should use given client base url for FullUrl only if BaseUrl isn't already set")
        Set Request = New RestRequest
        Request.RequireHTTPS = True
        
        Request.Resource = "status"
        
        .Expect(Request.FullUrl("facebook.com/api")).ToEqual "https://facebook.com/api/status"
    End With
    
    With Specs.It("should automatically add slash between base and resource")
        Set Request = New RestRequest
        Request.RequireHTTPS = True
        
        Request.Resource = "status"
        .Expect(Request.FullUrl("facebook.com/api")).ToEqual "https://facebook.com/api/status"
        
        Request.Resource = "/status"
        .Expect(Request.FullUrl("facebook.com/api")).ToEqual "https://facebook.com/api/status"
        
        Request.Resource = "status"
        .Expect(Request.FullUrl("facebook.com/api/")).ToEqual "https://facebook.com/api/status"
        
        Request.Resource = "/status"
        .Expect(Request.FullUrl("facebook.com/api/")).ToEqual "https://facebook.com/api/status"
    End With
    
    With Specs.It("should include content-type based on specified format")
        Set Request = New RestRequest
        
        Request.AddParameter "A", 123
        Request.Method = httpPOST
        
        ' JSON by default
        .Expect(Request.ContentType).ToEqual "application/json"
        
        Request.Format = json
        .Expect(Request.ContentType).ToEqual "application/json"
        
        Request.Format = formurlencoded
        .Expect(Request.ContentType).ToEqual "application/x-www-form-urlencoded;charset=UTF-8"
    End With
    
    With Specs.It("should override existing headers, url segments, and parameters")
        Set Request = New RestRequest
        
        Request.AddHeader "A", "abc"
        Request.AddHeader "A", "def"
        .Expect(Request.Headers.count).ToEqual 1
        .Expect(Request.Headers.Item("A")).ToEqual "def"
        
        Request.AddUrlSegment "A", "abc"
        Request.AddUrlSegment "A", "def"
        .Expect(Request.UrlSegments.count).ToEqual 1
        .Expect(Request.UrlSegments.Item("A")).ToEqual "def"
        
        Request.AddParameter "A", "abc"
        Request.AddParameter "A", "def"
        .Expect(Request.Parameters.count).ToEqual 1
        .Expect(Request.Parameters.Item("A")).ToEqual "def"
        
        Request.AddQuerystringParam "A", "abc"
        Request.AddQuerystringParam "A", "def"
        .Expect(Request.QuerystringParams.count).ToEqual 1
        .Expect(Request.QuerystringParams.Item("A")).ToEqual "def"
    End With
    
    With Specs.It("should handle Integer, Double, and Boolean variable types as parameters")
        Set Request = New RestRequest
        
        Dim A As Integer
        Dim B As Double
        Dim C As Boolean
        
        A = 20
        B = 3.14
        C = True
        
        Request.AddParameter "A", A
        Request.AddParameter "B", B
        Request.AddParameter "C", C
        
        Request.Method = httpPOST
        .Expect(Request.Body).ToEqual "{""A"":20,""B"":3.14,""C"":true}"
        
        Request.Method = httpGET
        .Expect(Request.FormattedResource).ToEqual "?A=20&B=3.14&C=true"
    End With
    
    With Specs.It("should allow body or body string for GET requests")
        Set Request = New RestRequest
        Request.Method = httpGET
        
        Set Body = New Dictionary
        Body.Add "A", 123
        
        Request.AddBody Body
        .Expect(Request.Body).ToEqual "{""A"":123}"
        
        Set Request = New RestRequest
        Request.Method = httpGET
        
        Request.AddBodyString "Howdy!"
        .Expect(Request.Body).ToEqual "Howdy!"
    End With
    
    With Specs.It("should format body based on set format")
        Set Request = New RestRequest
        Request.Method = httpPOST
        
        Request.AddParameter "A", 123
        Request.AddParameter "B", "Howdy!"
        
        ' JSON by default
        .Expect(Request.Body).ToEqual "{""A"":123,""B"":""Howdy!""}"
        
        Request.Format = json
        .Expect(Request.Body).ToEqual "{""A"":123,""B"":""Howdy!""}"
        
        Request.Format = formurlencoded
        .Expect(Request.Body).ToEqual "A=123&B=Howdy%21"
    End With
    
    With Specs.It("should allow array/collection for body")
        Set Request = New RestRequest
        
        Set Body = New Collection
        Body.Add "a"
        Body.Add "b"
        Body.Add "c"
        
        Request.AddBody Body
        .Expect(Request.Body).ToEqual "[""a"",""b"",""c""]"
        
        Request.AddBody Array("a", "b", "c")
        .Expect(Request.Body).ToEqual "[""a"",""b"",""c""]"
    End With
    
    InlineRunner.RunSuite Specs
End Function


