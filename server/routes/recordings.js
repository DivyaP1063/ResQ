const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs").promises;
const { AssemblyAI } = require("assemblyai");
const Recording = require("../models/Recording");
const { analyzeForEmergency } = require("../utils/emergencyAnalysis");
const emailService = require("../services/emailService");

const router = express.Router();

// Configure AssemblyAI
const assemblyai = new AssemblyAI({
  apiKey: process.env.ASSEMBLYAI_API_KEY || "your_api_key_here",
});

// Configure multer for audio file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = "uploads/recordings";
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, `recording-${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    console.log("Multer fileFilter - file:", file);
    const allowedMimes = [
      "audio/wav",
      "audio/mpeg",
      "audio/webm",
      "audio/ogg",
      "audio/mp4",
    ];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      console.log("Invalid mime type:", file.mimetype);
      cb(
        new Error(
          `Invalid audio file type: ${
            file.mimetype
          }. Allowed: ${allowedMimes.join(", ")}`
        )
      );
    }
  },
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
}).single("audio");

// Upload and process audio recording
router.post(
  "/upload",
  (req, res, next) => {
    console.log("=== UPLOAD ROUTE HIT ===");
    console.log("Request headers:", req.headers);
    console.log("Content-Type:", req.get("Content-Type"));
    next();
  },
  (req, res, next) => {
    upload(req, res, (err) => {
      if (err) {
        console.error("Multer error:", err);
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({ error: "File too large (max 50MB)" });
          }
          return res
            .status(400)
            .json({ error: `Upload error: ${err.message}` });
        }
        return res
          .status(400)
          .json({ error: `File processing error: ${err.message}` });
      }
      next();
    });
  },
  async (req, res) => {
    console.log("=== AFTER MULTER MIDDLEWARE ===");
    try {
      console.log("Upload request received, file:", req.file);
      console.log("User from auth middleware:", req.user);

      if (!req.file) {
        console.log("No file received");
        return res.status(400).json({ error: "Audio file is required" });
      }

      if (!req.user) {
        console.log("No user found - auth middleware failed");
        return res.status(401).json({ error: "Authentication required" });
      }

      console.log("Creating recording entry for user:", req.user._id);
      // Create recording entry
      const recording = new Recording({
        userId: req.user._id,
        filename: req.file.filename,
        originalName: req.file.originalname,
        filePath: req.file.path,
        metadata: {
          fileSize: req.file.size,
          mimeType: req.file.mimetype,
        },
      });

      console.log("Saving recording to database...");
      await recording.save();
      console.log("Recording saved with ID:", recording._id);

      // Process audio with AssemblyAI
      try {
        console.log(
          "Uploading file to AssemblyAI:",
          req.file.path,
          req.file.mimetype
        );

        // TEMPORARY: Skip AssemblyAI and simulate emergency detection for testing
        const isTestMode = false; // Set to false to use real AssemblyAI

        if (isTestMode) {
          // Simulate transcription and emergency detection
          const simulatedTranscription = "help me please emergency";
          recording.transcription = simulatedTranscription;
          recording.status = "completed";

          const emergencyAnalysis = analyzeForEmergency(simulatedTranscription);
          console.log("Emergency analysis result:", emergencyAnalysis);
          recording.isEmergency = emergencyAnalysis.isEmergency;
          recording.emergencyType = emergencyAnalysis.type;
          recording.confidence = emergencyAnalysis.confidence;
          recording.keywords = emergencyAnalysis.keywords;

          await recording.save();

          // Send emergency email if emergency is detected
          if (emergencyAnalysis.isEmergency) {
            try {
              console.log("Emergency detected! Sending notification emails...");
              const emailResult = await emailService.sendEmergencyAlert(req.user._id, {
                transcription: simulatedTranscription,
                type: emergencyAnalysis.type,
                confidence: emergencyAnalysis.confidence,
                keywords: emergencyAnalysis.keywords,
                timestamp: recording.createdAt,
                recordingId: recording._id
              });
              console.log("Emergency email notification result:", emailResult);
            } catch (emailError) {
              console.error("Failed to send emergency email:", emailError);
              // Don't fail the request if email sending fails
            }
          }

          res.json({
            message: "Recording processed successfully (TEST MODE)",
            recording: {
              id: recording._id,
              transcription: recording.transcription,
              isEmergency: recording.isEmergency,
              emergencyType: recording.emergencyType,
              confidence: recording.confidence,
              keywords: recording.keywords,
              createdAt: recording.createdAt,
            },
            assemblyAI: {
              fullResponse: { text: simulatedTranscription },
              processingTime: 0,
              detectedLanguage: 'en'
            },
            emergencyAnalysis: recording.isEmergency ? {
              matchedKeywords: recording.keywords,
              emergencyType: recording.emergencyType,
              confidenceScore: recording.confidence,
              riskLevel: recording.confidence > 0.7 ? 'HIGH' : recording.confidence > 0.4 ? 'MEDIUM' : 'LOW'
            } : null
          });
        } else {
          // Real AssemblyAI processing
          console.log("Starting real AssemblyAI transcription...");
          console.log("File path:", req.file.path);
          console.log("File size:", req.file.size);
          console.log("MIME type:", req.file.mimetype);

          // Check if file exists
          const fs = require("fs");
          if (!fs.existsSync(req.file.path)) {
            throw new Error("Audio file not found at path: " + req.file.path);
          }

          // Check file size - AssemblyAI has limits
          if (req.file.size > 50 * 1024 * 1024) {
            // 50MB
            throw new Error("File too large for AssemblyAI processing");
          }

          const transcript = await assemblyai.transcripts.transcribe({
            audio: req.file.path,
            speech_model: "best",
            language_detection: true,
            punctuate: true,
            format_text: true,
          });
          console.log("AssemblyAI transcript result:", transcript);

          // Update recording with transcription results
          recording.transcription = transcript.text || "";
          recording.assemblyAiId = transcript.id;
          recording.status =
            transcript.status === "completed" ? "completed" : "failed";

          // Analyze for emergency keywords
          if (transcript.text) {
            const emergencyAnalysis = analyzeForEmergency(transcript.text);
            console.log("Emergency analysis result:", emergencyAnalysis);
            recording.isEmergency = emergencyAnalysis.isEmergency;
            recording.emergencyType = emergencyAnalysis.type;
            recording.confidence = emergencyAnalysis.confidence;
            recording.keywords = emergencyAnalysis.keywords;

            // Send emergency email if emergency is detected
            if (emergencyAnalysis.isEmergency) {
              try {
                console.log("Emergency detected! Sending notification emails...");
                const emailResult = await emailService.sendEmergencyAlert(req.user._id, {
                  transcription: transcript.text,
                  type: emergencyAnalysis.type,
                  confidence: emergencyAnalysis.confidence,
                  keywords: emergencyAnalysis.keywords,
                  timestamp: recording.createdAt,
                  recordingId: recording._id
                });
                console.log("Emergency email notification result:", emailResult);
              } catch (emailError) {
                console.error("Failed to send emergency email:", emailError);
                // Don't fail the request if email sending fails
              }
            }
          }

          await recording.save();

          res.json({
            message: "Recording processed successfully",
            recording: {
              id: recording._id,
              transcription: recording.transcription,
              isEmergency: recording.isEmergency,
              emergencyType: recording.emergencyType,
              confidence: recording.confidence,
              keywords: recording.keywords,
              createdAt: recording.createdAt,
            },
            assemblyAI: {
              fullResponse: transcript,
              processingTime: transcript.audio_duration || 0,
              detectedLanguage: transcript.language_code || 'unknown'
            },
            emergencyAnalysis: recording.isEmergency ? {
              matchedKeywords: recording.keywords,
              emergencyType: recording.emergencyType,
              confidenceScore: recording.confidence,
              riskLevel: recording.confidence > 0.7 ? 'HIGH' : recording.confidence > 0.4 ? 'MEDIUM' : 'LOW'
            } : null
          });
        }
      } catch (transcriptionError) {
        console.error("Transcription error:", transcriptionError);
        if (transcriptionError.response) {
          console.error(
            "AssemblyAI error response:",
            transcriptionError.response.data
          );
        }

        // Fallback: Save recording without transcription but allow manual emergency detection
        recording.status = "completed"; // Mark as completed even without transcription
        recording.transcription =
          "Audio processing failed - manual review required";
        recording.isEmergency = false; // Default to no emergency when transcription fails
        recording.confidence = 0;

        await recording.save();

        // Return success response so frontend doesn't show error
        res.json({
          message: "Recording saved (transcription failed)",
          recording: {
            id: recording._id,
            transcription: recording.transcription,
            isEmergency: recording.isEmergency,
            emergencyType: recording.emergencyType,
            confidence: recording.confidence,
            keywords: recording.keywords,
            createdAt: recording.createdAt,
          },
        });
      }
    } catch (error) {
      console.error("Upload error:", error);
      console.error("Error stack:", error.stack);
      res.status(500).json({ error: "Failed to upload recording" });
    }
  }
);

// Get all recordings for user
router.get("/", async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const recordings = await Recording.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select("-filePath"); // Don't expose file paths

    const total = await Recording.countDocuments({ userId: req.user._id });

    res.json({
      recordings,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Fetch recordings error:", error);
    res.status(500).json({ error: "Failed to fetch recordings" });
  }
});

// Get emergency recordings only
router.get("/emergencies", async (req, res) => {
  try {
    const recordings = await Recording.find({
      userId: req.user._id,
      isEmergency: true,
    })
      .sort({ createdAt: -1 })
      .select("-filePath");

    res.json({ recordings });
  } catch (error) {
    console.error("Fetch emergency recordings error:", error);
    res.status(500).json({ error: "Failed to fetch emergency recordings" });
  }
});

// Get specific recording details
router.get("/:id", async (req, res) => {
  try {
    const recording = await Recording.findOne({
      _id: req.params.id,
      userId: req.user._id,
    }).select("-filePath");

    if (!recording) {
      return res.status(404).json({ error: "Recording not found" });
    }

    res.json({ recording });
  } catch (error) {
    console.error("Fetch recording error:", error);
    res.status(500).json({ error: "Failed to fetch recording" });
  }
});

// Delete recording
router.delete("/:id", async (req, res) => {
  try {
    const recording = await Recording.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!recording) {
      return res.status(404).json({ error: "Recording not found" });
    }

    // Delete file from filesystem
    try {
      await fs.unlink(recording.filePath);
    } catch (fileError) {
      console.error("File deletion error:", fileError);
    }

    // Delete from database
    await Recording.findByIdAndDelete(req.params.id);

    res.json({ message: "Recording deleted successfully" });
  } catch (error) {
    console.error("Delete recording error:", error);
    res.status(500).json({ error: "Failed to delete recording" });
  }
});

module.exports = router;
