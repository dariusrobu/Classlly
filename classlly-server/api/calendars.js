// Simple static JSON endpoint for academic calendars
const calendarsData = {
  "version": 2,
  "calendars": [
    {
      "universityName": "Universitatea Babeș-Bolyai (UBB)",
      "academicYear": "2025-2026",
      "sem1Start": "2025-09-29",
      "sem1End": "2026-02-22",
      "sem2Start": "2026-02-23",
      "sem2End": "2026-07-12",
      "events": [
        { "id": "ubb-s1-t1", "name": "Teaching Activity S1", "start": "2025-09-29", "end": "2025-12-21", "type": "teaching", "weeks": 12 },
        { "id": "ubb-s1-w", "name": "Winter Break", "start": "2025-12-22", "end": "2026-01-04", "type": "break", "weeks": 2 },
        { "id": "ubb-s1-t2", "name": "Teaching Activity S1 (Cont.)", "start": "2026-01-05", "end": "2026-01-18", "type": "teaching", "weeks": 2 },
        { "id": "ubb-s1-e", "name": "Exam Session S1", "start": "2026-01-19", "end": "2026-02-08", "type": "exam", "weeks": 3 },
        { "id": "ubb-s1-r", "name": "Retake Session S1", "start": "2026-02-16", "end": "2026-02-22", "type": "retake", "weeks": 1 },
        { "id": "ubb-s2-t1", "name": "Teaching Activity S2", "start": "2026-02-23", "end": "2026-04-12", "type": "teaching", "weeks": 7 },
        { "id": "ubb-s2-p", "name": "Easter Break", "start": "2026-04-13", "end": "2026-04-19", "type": "break", "weeks": 1 },
        { "id": "ubb-s2-t2", "name": "Teaching Activity S2 (Cont.)", "start": "2026-04-20", "end": "2026-06-07", "type": "teaching", "weeks": 7 },
        { "id": "ubb-s2-e", "name": "Exam Session S2", "start": "2026-06-08", "end": "2026-06-28", "type": "exam", "weeks": 3 },
        { "id": "ubb-s2-r", "name": "Retake Session S2", "start": "2026-07-06", "end": "2026-07-12", "type": "retake", "weeks": 1 }
      ]
    },
    {
      "universityName": "UTCN Cluj",
      "academicYear": "2025-2026",
      "sem1Start": "2025-09-29",
      "sem1End": "2026-02-22",
      "sem2Start": "2026-02-23",
      "sem2End": "2026-06-28",
      "events": [
        { "id": "utcn-s1-t1", "name": "Teaching Activity S1", "start": "2025-09-29", "end": "2025-12-19", "type": "teaching", "weeks": 12 },
        { "id": "utcn-s1-w", "name": "Winter Break", "start": "2025-12-22", "end": "2026-01-04", "type": "break", "weeks": 2 },
        { "id": "utcn-s1-t2", "name": "Teaching Activity S1 (Cont.)", "start": "2026-01-05", "end": "2026-01-18", "type": "teaching", "weeks": 2 },
        { "id": "utcn-s1-e", "name": "Exam Session S1", "start": "2026-01-19", "end": "2026-02-08", "type": "exam", "weeks": 3 },
        { "id": "utcn-s1-r", "name": "Consultations and Retakes", "start": "2026-02-16", "end": "2026-02-22", "type": "retake", "weeks": 1 },
        { "id": "utcn-s2-t1", "name": "Teaching Activity S2", "start": "2026-02-23", "end": "2026-04-12", "type": "teaching", "weeks": 7 },
        { "id": "utcn-s2-p", "name": "Easter Break", "start": "2026-04-13", "end": "2026-04-19", "type": "break", "weeks": 1 },
        { "id": "utcn-s2-t2", "name": "Teaching Activity S2 (Cont.)", "start": "2026-04-20", "end": "2026-06-07", "type": "teaching", "weeks": 7 },
        { "id": "utcn-s2-e", "name": "Exam Session S2", "start": "2026-06-08", "end": "2026-06-28", "type": "exam", "weeks": 3 }
      ]
    },
    {
      "universityName": "UMF \"Iuliu Hațieganu\" Cluj",
      "academicYear": "2025-2026",
      "sem1Start": "2025-09-29",
      "sem1End": "2026-02-20",
      "sem2Start": "2026-02-23",
      "sem2End": "2026-07-03",
      "events": [
        { "id": "umf-s1-t1", "name": "Teaching Activity S1", "start": "2025-09-29", "end": "2025-12-19", "type": "teaching", "weeks": 12 },
        { "id": "umf-s1-h", "name": "Christmas Holiday", "start": "2025-12-22", "end": "2026-01-02", "type": "break", "weeks": 2 },
        { "id": "umf-s1-t2", "name": "Teaching Activity S1 (Cont.)", "start": "2026-01-05", "end": "2026-01-16", "type": "teaching", "weeks": 2 },
        { "id": "umf-s1-e", "name": "Exam Session S1", "start": "2026-01-19", "end": "2026-02-13", "type": "exam", "weeks": 4 },
        { "id": "umf-s2-t1", "name": "Teaching Activity S2", "start": "2026-02-23", "end": "2026-06-05", "type": "teaching", "weeks": 14 },
        { "id": "umf-s2-p", "name": "Easter Holiday", "start": "2026-04-13", "end": "2026-04-17", "type": "break", "weeks": 1 },
        { "id": "umf-s2-e", "name": "Exam Session S2", "start": "2026-06-08", "end": "2026-07-03", "type": "exam", "weeks": 4 }
      ]
    },
    {
      "universityName": "ULBS Sibiu (General Structure)",
      "academicYear": "2025-2026",
      "sem1Start": "2025-10-01",
      "sem1End": "2026-03-01",
      "sem2Start": "2026-03-02",
      "sem2End": "2026-07-12",
      "events": [
        { "id": "ulbs-s1-t1", "name": "Teaching Activity S1", "start": "2025-10-01", "end": "2025-12-21", "type": "teaching", "weeks": 12 },
        { "id": "ulbs-s1-w", "name": "Winter Holiday", "start": "2025-12-22", "end": "2026-01-11", "type": "break", "weeks": 3 },
        { "id": "ulbs-s1-t2", "name": "Teaching Activity S1 (Cont.)", "start": "2026-01-12", "end": "2026-01-25", "type": "teaching", "weeks": 2 },
        { "id": "ulbs-s1-e", "name": "Exam Session S1", "start": "2026-01-26", "end": "2026-02-15", "type": "exam", "weeks": 3 },
        { "id": "ulbs-s1-r", "name": "Retake Session S1", "start": "2026-02-23", "end": "2026-03-01", "type": "retake", "weeks": 1 },
        { "id": "ulbs-s2-t1", "name": "Teaching Activity S2", "start": "2026-03-02", "end": "2026-04-12", "type": "teaching", "weeks": 6 },
        { "id": "ulbs-s2-p", "name": "Easter Holiday", "start": "2026-04-13", "end": "2026-04-19", "type": "break", "weeks": 1 },
        { "id": "ulbs-s2-t2", "name": "Teaching Activity S2 (Cont.)", "start": "2026-04-20", "end": "2026-06-14", "type": "teaching", "weeks": 8 },
        { "id": "ulbs-s2-e", "name": "Exam Session S2", "start": "2026-06-15", "end": "2026-07-05", "type": "exam", "weeks": 3 },
        { "id": "ulbs-s2-r", "name": "Retake Session S2", "start": "2026-07-06", "end": "2026-07-12", "type": "retake", "weeks": 1 }
      ]
    }
  ]
};

export default function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
  res.status(200).json(calendarsData);
}
