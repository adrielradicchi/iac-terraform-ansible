from locust import FastHttpUser, task

class WebsiteUser(FastHttpUser):
    host = "http://localhost:8089"

    @task
    def load_test(self):
        self.client.get("/clientes")
