FROM python:3.12-slim
WORKDIR /app
COPY tools/validator/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY . /workspace
WORKDIR /workspace
CMD ["python", "tools/validator/validate_questions.py"]
