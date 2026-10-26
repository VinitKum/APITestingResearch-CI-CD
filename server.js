const http = require("node:http");

const PORT = 3000;

const users = [
    { id: 1, name: "Vinit" },
    { id: 2, name: "QA User" }
];

const server = http.createServer((req, res) => {
    const path = new URL(
        req.url,
        "http://127.0.0.1"
    ).pathname;

    res.setHeader(
        "Content-Type",
        "application/json; charset=utf-8"
    );

    if (req.method === "GET" && path === "/health") {
        res.writeHead(200);
        res.end(JSON.stringify({ status: "UP" }));
        return;
    }

    if (req.method === "GET" && path === "/users") {
        res.writeHead(200);
        res.end(JSON.stringify(users));
        return;
    }

    res.writeHead(404);
    res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(PORT, "127.0.0.1", () => {
    console.log(`Demo API running on port ${PORT}`);
});