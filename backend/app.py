from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg
from psycopg.rows import dict_row
import os

app = Flask(__name__)
CORS(app)


def get_db_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST", "database"),
        port=os.getenv("DB_PORT", "5432"),
        user=os.getenv("DB_USER", "lms_user"),
        password=os.getenv("DB_PASSWORD"),
        dbname=os.getenv("DB_NAME", "lms_db"),
        row_factory=dict_row
    )


@app.route("/")
def home():
    return jsonify({
        "message": "College Event Portal Backend is running"
    })


@app.route("/health")
def health():
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")

        return jsonify({
            "status": "healthy",
            "database": "connected"
        }), 200

    except psycopg.Error:
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected"
        }), 503


@app.route("/api/events", methods=["GET"])
def get_events():
    with get_db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM events ORDER BY id")
            events = cursor.fetchall()

    return jsonify(events)


@app.route("/api/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}

    required_fields = [
        "event_id",
        "student_name",
        "email",
        "college",
        "department",
        "phone"
    ]

    if any(data.get(field) is None for field in required_fields):
        return jsonify({"error": "All registration fields are required"}), 400

    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:

                cursor.execute(
                    """
                    UPDATE events
                    SET available_seats = available_seats - 1
                    WHERE id = %s AND available_seats > 0
                    RETURNING id
                    """,
                    (data["event_id"],)
                )

                event = cursor.fetchone()

                if not event:
                    cursor.execute(
                        "SELECT id FROM events WHERE id = %s",
                        (data["event_id"],)
                    )

                    if not cursor.fetchone():
                        return jsonify({"error": "Event not found"}), 404

                    return jsonify({"error": "No seats available"}), 400

                cursor.execute(
                    """
                    INSERT INTO registrations
                    (event_id, student_name, email, college, department, phone)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        data["event_id"],
                        data["student_name"],
                        data["email"],
                        data["college"],
                        data["department"],
                        data["phone"]
                    )
                )

        return jsonify({"message": "Registration successful"}), 201

    except psycopg.Error:
        app.logger.exception("Registration database operation failed")
        return jsonify({"error": "Registration failed"}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
