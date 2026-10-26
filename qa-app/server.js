const http = require("node:http");

// Isolated QA demo application. Do not change the existing API on port 3000.
const PORT = 3001;

const users = [
    { id: 1, name: "Vinit", role: "QA Engineer" },
    { id: 2, name: "Demo User", role: "Developer" }
];

const server = http.createServer((req, res) => {
    const path = new URL(req.url, "http://127.0.0.1").pathname;
    res.setHeader("Content-Type", "application/json; charset=utf-8");

    if (req.method === "GET" && path === "/health") {
        res.writeHead(200);
        res.end(JSON.stringify({ status: "UP", environment: "QA" }));
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
    console.log(`QA application running on port ${PORT}`);
});
