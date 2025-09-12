from flask import Flask, render_template
import json
import os

app = Flask(__name__)

@app.route('/')
def index():
    filename = os.path.dirname(os.path.realpath(__file__)) + "/prompt.json"
    prompt_json = open(filename , "r")
    prompt_list = json.load(prompt_json)
    return render_template('index.html', list=prompt_list)

if __name__ == '__main__':
    app.debug = True
    app.run(debug=False, host='0.0.0.0', port=8080)
