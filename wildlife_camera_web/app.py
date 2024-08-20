from flask import Flask, send_from_directory, render_template_string, send_file
import os

app = Flask(__name__)

PHOTO_DIR = '/home/fuzib/wildlife_camera/photos'  

@app.route('/')
def index():
    # Generate a list of all images and corresponding JSON files
    file_structure = {}
    for root, dirs, files in os.walk(PHOTO_DIR):
        date = os.path.basename(root)
        if date:
            file_structure[date] = []
            for file in files:
                if file.endswith('.jpg'):
                    json_file = file.replace('.jpg', '.json')
                    file_structure[date].append({
                        'image': file,
                        'json': json_file
                    })
    
    # Render a simple HTML page
    html = """
    <h1>Wildlife Camera Photos</h1>
    <a href="/logs">Click here to download logs</a>
    {% for date, files in file_structure.items() %}
        <h2>{{ date }}</h2>
        <ul>
        {% for file in files %}
            <li>
                <img src="/photos/{{ date }}/{{ file.image }}" style="max-width: 300px;"><br>
                <a href="/photos/{{ date }}/{{ file.json }}">Metadata ({{ file.json }})</a>
            </li>
        {% endfor %}
        </ul>
    {% endfor %}
    """
    return render_template_string(html, file_structure=file_structure)

@app.route('/photos/<path:filename>')
def photos(filename):
    # Serve the image and JSON files
    return send_from_directory(PHOTO_DIR, filename)
    
@app.route('/logs')
def get_logs():
    log_file_path = '/home/fuzib/wildlife_camera/logs/wildlife_camera.log'
    return send_file(log_file_path, as_attachment=False)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
