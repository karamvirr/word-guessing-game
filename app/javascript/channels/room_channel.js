import consumer from "channels/consumer"

let slug = window.location.href.split('/').slice(-1)[0];
let drawInvocationCount = 0;
if (slug && slug.length > 0) {
  const roomChannel = consumer.subscriptions.create({ channel: 'RoomChannel', slug: slug }, {
    connected() {
      console.log('connected - roomchannel');
      roomChannel.perform('toggle_display');
      //this.perform('connected');
    },

    disconnected() {
      console.log('disconnected - roomchannel');
    },

    received(data) {
      switch (data.context) {
        case 'connection':
          this.updatePlayerRoster(data.payload);
          this.appendConnectionMessage(data.payload);
          break;
        case 'draw':
          //console.log('draw', data.payload);
          drawInvocationCount++;
          console.log('draw invocations:', drawInvocationCount);
          this.drawLine(data.payload);
          break;
        case 'timer':
          this.updateTimeRemaining(data.payload);
          break;
        case 'toggle_display':
          this.toggleDisplay(data.payload);
          break;
        case 'start':
          this.startGame()
          break;
        case 'stop':
          this.stopGame();
          this.clearCanvas();
          break;
      };
    },

    clearCanvas() {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
    },

    stopGame() {
      document.querySelector('#time-remaining').innerHTML = '60s';
    },

    startGame() {
      console.log('start');
      let interval = setInterval(() => {
        let timer = document.querySelector('#time-remaining');
        if (parseInt(timer.innerHTML) === 0) {
          console.log('done');
          window.clearInterval(interval);
          roomChannel.perform('stop')
        } else {
          let secondsRemaining = parseInt(timer.innerHTML) - 1;
          roomChannel.perform('timer', { seconds: secondsRemaining });
        }
      }, 1000);
    },


    getPlayerId() {
      return parseInt(document.querySelector('.player-container').id);
    },

    toggleDisplay(data) {
      if (this.getPlayerId() === data.drawer_id) {
        document.querySelector('#start-game').parentNode.classList.remove('hidden');
      } else {
        document.querySelector('#start-game').parentNode.classList.add('hidden');
      }
    },

    updateTimeRemaining(data) {
      document.querySelector('#time-remaining').innerHTML = `${data.seconds}s`;
    },

    // https://codingshower.com/convert-html-string-to-dom-node/
    updatePlayerRoster(data) {
      let current_user_id = this.getPlayerId();
      let players = [];
      data.users.forEach((element) => {
        let playerCardHTML = `
          <li class="player-card" id="${element.id}">
            <p>
              <b>${element.name} ${((current_user_id === element.id) ? '(you)' : '')}</b>
              <br>
              <span>${element.score} PTS</span>
            </p>
            ${(element.id === data.drawer_id) ?
              `<i class="fa fa-pencil" style="font-size: 35px"></i>` : ""}
          </li>
        `;
        const range = document.createRange();
        const playerCard = range.createContextualFragment(playerCardHTML);
        players.push(playerCard);
      });
      document.querySelector('.player-container').replaceChildren(...players);
    },

    drawLine(data) {
      ctx.lineWidth = 2;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round'

      ctx.beginPath();
      ctx.moveTo(data.x, data.y);
      ctx.lineTo(data.px, data.py); // to
      ctx.stroke(); // draw it!
    },

    appendConnectionMessage(data) {
      let chat = document.querySelector('.message-container');
      let message = `
        <li>
          <p class="message" style="color:#${data.color}"">
            ${data.content}
          </p>
        </li>
      `;
      chat.insertAdjacentHTML("beforeend", message);
      chat.scrollTo({
        top: chat.scrollHeight,
        left: 0,
        behavior: 'smooth'
      });
    },
  });

  document.querySelector('#start-game').addEventListener('click', (event) => {
    event.preventDefault();
    let word = prompt('Enter a word:');
    document.querySelector('#start-game').parentNode.classList.add('hidden');
    roomChannel.perform('start', { current_word: word })
  });

  let canvas = document.querySelector('canvas');
  let ctx = canvas.getContext('2d');
  const offset = canvas.getBoundingClientRect();
  let drawing = false;
  let startX, startY, endX, endY;


  // Sending data to the socket
  function emitDrawing() {
    const data = {
      x: startX,
      y: startY,
      px: endX,
      py: endY
    }
    // Calls 'RoomChannel#draw' on the server.
    roomChannel.perform('draw', data);
  }

  canvas.addEventListener('mouseleave', () => {
    drawing = false
  });
  canvas.addEventListener('mousedown', () => {
    drawing = true;
    const scaleX = canvas.width / offset.width;
    const scaleY = canvas.height / offset.height;

    startX = (event.clientX - offset.left) * scaleX;
    startY = (event.clientY - offset.top) * scaleY;
  });
  canvas.addEventListener('mouseup', () =>  {
    drawing = false;
  });

  canvas.addEventListener('mousemove', (event) => {
    if (drawing) {
      const scaleX = canvas.width / offset.width;
      const scaleY = canvas.height / offset.height;

      endX = (event.clientX - offset.left) * scaleX;
      endY = (event.clientY - offset.top) * scaleY;

      emitDrawing()
      startX = endX;
      startY = endY;
    }
  });
}
