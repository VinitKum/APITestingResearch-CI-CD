import io.restassured.RestAssured.*;
import io.restassured.http.ContentType;
import io.restassured.matcher.RestAssuredMatchers.*;
import org.hamcrest.Matchers.*;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;

public class simpleTest
{
    @Test
    public void getTest()
    {
        given()
                .contentType(ContentType.JSON)
                .when().get("http://localhost:3000/users")
                .then().statusCode(200);
    }

}
