from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector
import os

app = Flask(__name__)
CORS(app)


def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "database"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "rootpassword"),
        database=os.getenv("DB_NAME", "college_event_db")
    )


@app.route("/")
def home():
    return jsonify({
        "message": "College Event Portal Backend is running"
    })


@app.route("/api/events", methods=["GET"])
def get_events():

    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute("SELECT * FROM events")

    events = cursor.fetchall()

    cursor.close()
    connection.close()

    return jsonify(events)


@app.route("/api/register", methods=["POST"])
def register():

    data = request.json

    event_id = data.get("event_id")
    student_name = data.get("student_name")
    email = data.get("email")
    college = data.get("college")
    department = data.get("department")
    phone = data.get("phone")

    connection = get_db_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        SELECT available_seats
        FROM events
        WHERE id = %s
        """,
        (event_id,)
    )

    event = cursor.fetchone()

    if not event:
        cursor.close()
        connection.close()

        return jsonify({
            "error": "Event not found"
        }), 404

    if event[0] <= 0:
        cursor.close()
        connection.close()

        return jsonify({
            "error": "No seats available"
        }), 400

    cursor.execute(
        """
        INSERT INTO registrations
        (event_id, student_name, email, college, department, phone)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (
            event_id,
            student_name,
            email,
            college,
            department,
            phone
        )
    )

    cursor.execute(
        """
        UPDATE events
        SET available_seats = available_seats - 1
        WHERE id = %s
        """,
        (event_id,)
    )

    connection.commit()

    cursor.close()
    connection.close()

    return jsonify({
        "message": "Registration successful"
    })


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )