import io.restassured.http.ContentType;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;

public class simpleTest {
    @Test
    public void getTest() {
        // Jenkins passes the deployed QA base URL. Locally, default to the existing API.
        String baseUrl = System.getProperty("baseUrl", "http://127.0.0.1:3000");

        given()
                .contentType(ContentType.JSON)
                .when()
                .get(baseUrl + "/users")
                .then()
                .statusCode(200);
    }
}
