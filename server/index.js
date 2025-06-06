// Very 1st script of node js
console.log('');
console.log("******* Network Programming Project Server Side *******");
console.log('');


// Internal Pacakages
const express = require('express');

// External Packages
const authRouter = require('./routes/auth.js');
const { default: mongoose } = require('mongoose');

// INIT
const app = express();
const PORT = 9000;
const DB = "Add here mongodb url";

// Middle ware (Sending Data Like Client => (MiddleWare) => Server)
app.use(express.json());
app.use(authRouter);

// Connections
mongoose.connect(DB).then(() => {
    console.log('Mongose connection successful');
})
    .catch((e) => {
        console.log(e);
    });

app.listen(PORT, "0.0.0.0", () => {
    console.log(`connected at port ${PORT}`);
});
