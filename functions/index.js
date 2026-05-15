/**
 * VetClick Cloud Functions
 * ===========================
 * 1. programarRecordatorioCita: firestore onCreate en citas -> programa tarea en scheduledTasks
 * 2. recordatorioVacunasDiario: pubsub cron 9:00 Europe/Madrid -> busca vacunas proximas 7 dias
 * 3. webhookTwilio: https onRequest -> recibe respuestas SI/NO, actualiza estado cita
 * 4. procesarTareasProgramadas: pubsub cada 5 min -> busca tareas no procesadas, envia WhatsApp
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// ============ Helper Functions ============

/**
 * Formatea una fecha para mostrar en mensajes
 * @param {Date} fecha
 * @return {string}
 */
function formatearFecha(fecha) {
  if (!fecha || isNaN(fecha.getTime())) return "";
  return fecha.toLocaleDateString("es-ES", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

/**
 * Formatea una hora para mostrar en mensajes
 * @param {Date} fecha
 * @return {string}
 */
function formatearHora(fecha) {
  if (!fecha || isNaN(fecha.getTime())) return "";
  return fecha.toLocaleTimeString("es-ES", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Genera el mensaje de recordatorio de cita
 * @param {Object} cita
 * @param {string} nombreClinica
 * @return {string}
 */
function generarMensajeRecordatorio(cita, nombreClinica) {
  const fechaStr = formatearFecha(cita.fechaHora.toDate());
  const horaStr = formatearHora(cita.fechaHora.toDate());
  return `Hola ${cita.propietarioNombre ?? ""}, le recordamos que tiene una cita para ${cita.mascotaNombre ?? "su mascota"} el ${fechaStr} a las ${horaStr} en ${nombreClinica ?? "nuestra clinica"}. Motivo: ${cita.motivo ?? "consulta"}.\n\nConfirme su asistencia respondiendo SI o NO.`;
}

/**
 * Genera el mensaje de recordatorio de vacuna
 * @param {Object} mascota
 * @param {Object} vacuna
 * @param {string} nombreClinica
 * @return {string}
 */
function generarMensajeVacuna(mascota, vacuna, nombreClinica) {
  const proximaFecha = vacuna.proximaFecha ?
    formatearFecha(vacuna.proximaFecha.toDate()) : "";
  return `Hola ${mascota.propietario?.nombre ?? ""}, le recordamos que a ${mascota.nombre ?? "su mascota"} le corresponde la vacuna de ${vacuna.nombre ?? ""}${proximaFecha ? " el " + proximaFecha : ""}.\n\nPor favor, contacte con ${nombreClinica ?? "nosotros"} para programar la cita.`;
}

/**
 * Obtiene el nombre de la clinica
 * @param {string} clinicaId
 * @return {Promise<string>}
 */
async function getNombreClinica(clinicaId) {
  try {
    const doc = await db.collection("clinicas").doc(clinicaId).get();
    return doc.exists ? doc.data().nombre : "VetClick";
  } catch (e) {
    console.error("Error obteniendo clinica:", e);
    return "VetClick";
  }
}

// ============ Function 1: Programar Recordatorio de Cita ============

exports.programarRecordatorioCita = onDocumentCreated(
  {
    document: "citas/{citaId}",
    region: "europe-west1",
  },
  async (event) => {
    const cita = event.data.data();
    const citaId = event.params.citaId;

    if (!cita || !cita.enviarRecordatorio || cita.estado === "cancelada") {
      console.log(`Cita ${citaId}: no requiere recordatorio`);
      return null;
    }

    try {
      const fechaHora = cita.fechaHora.toDate();
      const ahora = new Date();

      // Programar recordatorio a 24h
      const recordatorio24h = new Date(fechaHora.getTime() - 24 * 60 * 60 * 1000);
      if (recordatorio24h > ahora) {
        await db.collection("scheduledTasks").add({
          tipo: "recordatorio_cita_24h",
          citaId: citaId,
          clinicaId: cita.clinicaId,
          mascotaNombre: cita.mascotaNombre || "",
          propietarioNombre: cita.propietarioNombre || "",
          propietarioTelefono: cita.propietarioTelefono || "",
          fechaHora: cita.fechaHora,
          motivo: cita.motivo || "",
          procesada: false,
          fechaEjecucion: admin.firestore.Timestamp.fromDate(recordatorio24h),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Cita ${citaId}: programado recordatorio 24h`);
      }

      // Programar recordatorio a 2h
      const recordatorio2h = new Date(fechaHora.getTime() - 2 * 60 * 60 * 1000);
      if (recordatorio2h > ahora) {
        await db.collection("scheduledTasks").add({
          tipo: "recordatorio_cita_2h",
          citaId: citaId,
          clinicaId: cita.clinicaId,
          mascotaNombre: cita.mascotaNombre || "",
          propietarioNombre: cita.propietarioNombre || "",
          propietarioTelefono: cita.propietarioTelefono || "",
          fechaHora: cita.fechaHora,
          motivo: cita.motivo || "",
          procesada: false,
          fechaEjecucion: admin.firestore.Timestamp.fromDate(recordatorio2h),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Cita ${citaId}: programado recordatorio 2h`);
      }

      return null;
    } catch (error) {
      console.error(`Error programando recordatorio cita ${citaId}:`, error);
      return null;
    }
  }
);

// ============ Function 2: Recordatorio de Vacunas Diario ============

exports.recordatorioVacunasDiario = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async (event) => {
    try {
      const ahora = new Date();
      const en7Dias = new Date(ahora.getTime() + 7 * 24 * 60 * 60 * 1000);
      const en7DiasTimestamp = admin.firestore.Timestamp.fromDate(en7Dias);

      // Buscar vacunas con proximaFecha en los proximos 7 dias
      // que no hayan tenido recordatorio enviado
      const snapshot = await db
        .collectionGroup("vacunas")
        .where("recordatorioEnviado", "==", false)
        .where("proximaFecha", ">=", admin.firestore.Timestamp.fromDate(ahora))
        .where("proximaFecha", "<=", en7DiasTimestamp)
        .get();

      console.log(`Vacunas a notificar: ${snapshot.size}`);

      for (const doc of snapshot.docs) {
        const vacuna = doc.data();

        try {
          // Obtener referencias desde la ruta del documento:
          // clinica/{clinicaId}/mascotas/{mascotaId}/vacunas/{vacunaId}
          const mascotaRef = doc.ref.parent.parent;
          const clinicaRef = mascotaRef.parent.parent;
          const clinicaId = clinicaRef.id;
          const mascotaId = mascotaRef.id;

          const mascotaDoc = await mascotaRef.get();

          if (!mascotaDoc.exists) {
            console.log(`Mascota ${mascotaId} no encontrada`);
            continue;
          }

          const mascota = mascotaDoc.data();
          const nombreClinica = await getNombreClinica(clinicaId);

          // Obtener numero de WhatsApp de la clinica
          const clinicaDoc = await clinicaRef.get();
          const clinicaData = clinicaDoc.exists ? clinicaDoc.data() : {};
          const numeroWhatsApp = clinicaData.configuracionWhatsApp?.numero || "";

          // Programar tarea de envio
          await db.collection("scheduledTasks").add({
            tipo: "recordatorio_vacuna",
            mascotaId: mascotaId,
            clinicaId: clinicaId,
            mascotaNombre: mascota.nombre || "",
            propietarioNombre: mascota.propietario?.nombre || "",
            propietarioTelefono: mascota.propietario?.telefono || "",
            vacunaNombre: vacuna.nombre || "",
            proximaFecha: vacuna.proximaFecha,
            numeroWhatsAppClinica: numeroWhatsApp,
            procesada: false,
            fechaEjecucion: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Marcar como recordatorio enviado
          await doc.ref.update({
            recordatorioEnviado: true,
            recordatorioEnviadoAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`Recordatorio vacuna programado para ${mascota.nombre}`);
        } catch (innerError) {
          console.error("Error procesando vacuna:", innerError);
        }
      }

      return null;
    } catch (error) {
      console.error("Error en recordatorioVacunasDiario:", error);
      return null;
    }
  }
);

// ============ Function 3: Webhook Twilio ============

exports.webhookTwilio = onRequest(
  {
    region: "europe-west1",
    cors: true,
  },
  async (request, response) => {
    // Solo aceptar POST
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const from = request.body.From || "";
      const body = (request.body.Body || "").trim().toUpperCase();
      const to = request.body.To || "";

      console.log(`SMS recibido de ${from}: ${body}`);

      // Guardar respuesta en Firestore
      await db.collection("webhookResponses").add({
        telefono: from,
        respuesta: body,
        destino: to,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Buscar citas pendientes para este telefono en todas las clinicas
      const telefonoLimpio = from.replace("+", "").replace(" ", "").replace("whatsapp:", "");
      const citasSnapshot = await db
        .collectionGroup("citas")
        .where("propietarioTelefono", "==", telefonoLimpio)
        .where("estado", "in", ["pendiente", "confirmada"])
        .orderBy("fechaHora", "desc")
        .limit(5)
        .get();

      if (citasSnapshot.empty) {
        console.log(`No se encontraron citas para ${from}`);
        // Responder con TwiML
        response.set("Content-Type", "text/xml");
        response.send(`<?xml version="1.0" encoding="UTF-8"?>
          <Response>
            <Message>No encontramos citas pendientes asociadas a este numero.</Message>
          </Response>`);
        return;
      }

      // Actualizar estado segun respuesta
      const nuevaRespuesta = body;
      let nuevoEstado = null;
      let mensajeRespuesta = "";

      if (nuevaRespuesta === "SI" || nuevaRespuesta === "SÍ") {
        nuevoEstado = "confirmada";
        mensajeRespuesta = "Gracias, su cita ha sido confirmada. Le esperamos.";
      } else if (nuevaRespuesta === "NO") {
        nuevoEstado = "cancelada";
        mensajeRespuesta = "Su cita ha sido cancelada. Pongase en contacto con nosotros para reprogramarla.";
      } else {
        mensajeRespuesta = "Por favor responda SI para confirmar o NO para cancelar su cita.";
      }

      if (nuevoEstado) {
        const batch = db.batch();
        citasSnapshot.docs.forEach((doc) => {
          batch.update(doc.ref, {
            estado: nuevoEstado,
            respuestaCliente: nuevaRespuesta,
            respuestaAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        await batch.commit();
        console.log(`Citas actualizadas a ${nuevoEstado}`);
      }

      // Responder con TwiML
      response.set("Content-Type", "text/xml");
      response.send(`<?xml version="1.0" encoding="UTF-8"?>
        <Response>
          <Message>${mensajeRespuesta}</Message>
        </Response>`);
    } catch (error) {
      console.error("Error en webhookTwilio:", error);
      response.set("Content-Type", "text/xml");
      response.status(500).send(`<?xml version="1.0" encoding="UTF-8"?>
        <Response>
          <Message>Ha ocurrido un error. Por favor contacte directamente con la clinica.</Message>
        </Response>`);
    }
  }
);

// ============ Function 4: Procesar Tareas Programadas ============

exports.procesarTareasProgramadas = onSchedule(
  {
    schedule: "*/5 * * * *",
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async (event) => {
    try {
      const ahora = admin.firestore.Timestamp.now();

      // Buscar tareas no procesadas con fecha de ejecucion pasada
      const snapshot = await db
        .collection("scheduledTasks")
        .where("procesada", "==", false)
        .where("fechaEjecucion", "<=", ahora)
        .limit(50)
        .get();

      console.log(`Tareas pendientes: ${snapshot.size}`);

      for (const doc of snapshot.docs) {
        const tarea = doc.data();

        try {
          if (tarea.tipo.startsWith("recordatorio_cita")) {
            const nombreClinica = await getNombreClinica(tarea.clinicaId);
            const mensaje = generarMensajeRecordatorio(
              {
                propietarioNombre: tarea.propietarioNombre,
                mascotaNombre: tarea.mascotaNombre,
                fechaHora: tarea.fechaHora,
                motivo: tarea.motivo,
              },
              nombreClinica
            );

            // Aqui se integraria el envio real por Twilio
            console.log(`[ENVIAR WhatsApp a ${tarea.propietarioTelefono}]: ${mensaje}`);

            // Marcar como procesada
            await doc.ref.update({
              procesada: true,
              procesadaAt: admin.firestore.FieldValue.serverTimestamp(),
              mensajeEnviado: mensaje,
            });
          } else if (tarea.tipo === "recordatorio_vacuna") {
            const mascotaRef = db.collection("mascotas").doc(tarea.mascotaId);
            const mascotaDoc = await mascotaRef.get();

            if (mascotaDoc.exists) {
              const mascota = mascotaDoc.data();
              const nombreClinica = await getNombreClinica(tarea.clinicaId);
              const mensaje = generarMensajeVacuna(
                mascota,
                {nombre: tarea.vacunaNombre, proximaFecha: tarea.proximaFecha},
                nombreClinica
              );

              console.log(`[ENVIAR WhatsApp a ${tarea.propietarioTelefono}]: ${mensaje}`);

              await doc.ref.update({
                procesada: true,
                procesadaAt: admin.firestore.FieldValue.serverTimestamp(),
                mensajeEnviado: mensaje,
              });
            }
          }
        } catch (innerError) {
          console.error(`Error procesando tarea ${doc.id}:`, innerError);
          // Marcar como procesada con error para no reintentar indefinidamente
          await doc.ref.update({
            procesada: true,
            error: innerError.message || String(innerError),
            procesadaAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      return null;
    } catch (error) {
      console.error("Error en procesarTareasProgramadas:", error);
      return null;
    }
  }
);
