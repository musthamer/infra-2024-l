package experiment;

import jakarta.servlet.http.*;
import jakarta.servlet.*;
import java.io.*;

public class Servlet701 extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/plain");
        resp.getWriter().println("Hello from Servlet701!");
    }
}
