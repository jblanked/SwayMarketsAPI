# SwayMarkets documentation: https://sway-technologies.gitbook.io/swaycharts-api-docs
import requests


class SwayMarkets:
    base_url = "https://api.swaycharts.io/dxsca-web/"
    session_token = ""
    username = ""
    account_name = ""

    def login(self, username, password, account_name="default:") -> bool:
        login_url = f"{self.base_url}login"

        login_data = {
            "username": username,
            "domain": "default",
            "password": password,
        }
        self.username = username
        self.account_name = f"default:{account_name}"
        response = requests.post(login_url, json=login_data)
        if response.status_code == 200:
            data = response.json()
            self.session_token = data["sessionToken"]
            return True
        else:
            return False

    def logout(self) -> bool:
        logout_url = f"{self.base_url}logout"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        response = requests.post(logout_url, headers=headers)
        if response.status_code == 200:
            return True
        else:
            return False

    def account_summary(self):
        url = f"{self.base_url}accounts/{self.account_name}/metrics"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            return data["metrics"][0]
        else:
            return {"error": f"GET request failed, status code {response.status_code}"}

    def get_users(self):
        url = f"{self.base_url}users/{self.username}@default"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            return data
        else:
            return {"error": f"GET request failed, status code {response.status_code}"}

    def ping(self):
        ping_url = f"{self.base_url}ping"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        response = requests.post(ping_url, headers=headers)
        if response.status_code == 200:
            return True
        else:
            return False

    def send_order(self, order_code: str, symbol: str, quantity: int, side: str) -> str:
        ping_url = f"{self.base_url}accounts/{self.account_name}/orders"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        order_data = {
            "orderCode": order_code,  # unique name/number for each order
            "type": "MARKET",  # MARKET, LIMIT, STOP
            "instrument": symbol,  # symbol
            "quantity": quantity,  # almost like lotsize, 10000 = 0.10 lot
            "positionEffect": "OPEN",
            "side": side,  # BUY or SELL
            "tif": "GTC",  # time in force/expiration of order
        }
        response = requests.post(ping_url, headers=headers, json=order_data)
        if response.status_code == 200:
            return response.json()["orderId"]
        elif response.status_code == 409:
            return "OrderID already exists"
        else:
            return "Error: Order not placed"

    def close_position(
        self,
        order_code: str,  # unique name/number for each order
        symbol: str,  # same symbol as the one used to open the position
        side: str,  # opposite side of the position, so if you opened a buy position, you close with a sell
        position_code: str,  # position code of the position you want to close
    ) -> bool:
        ping_url = f"{self.base_url}accounts/{self.account_name}/orders"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        order_data = {
            "orderCode": order_code,  # unique name/number for each order
            "type": "MARKET",
            "instrument": symbol,  # symbol from the initial position
            "positionEffect": "CLOSE",
            "side": side,  # BUY or SELL - opposite of the initial position
            "tif": "GTC",  # time in force/expiration of order
            "positionCode": position_code,  # position code of the position you want to close
        }
        response = requests.post(ping_url, headers=headers, json=order_data)
        if response.status_code == 200:
            return True
        else:
            return False

    # closing limit/stop orders
    def close_order(self, order_id: str) -> bool:
        close_url = f"{self.base_url}accounts/{self.account_name}/orders/{order_id}"

        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"DXAPI {self.session_token}",
        }
        response = requests.delete(close_url, headers=headers)
        if response.status_code == 200:
            return True
        else:
            return False
