import consumer from "channels/consumer"

(() => {
  const split = window.location.pathname.split('/');
  if (split[1] === 'room' && typeof split[2] === 'string') {
    const slug = split[2];
    const channel = consumer.subscriptions.create({ channel: 'RoomChannel', slug: slug }, {
      // Called when the subscription is ready for user on the server.
      connected() {
        console.log('welcome to the party!');
      },

      // Called when the subscription has been terminated by the server.
      disconnected() {
        console.log('thanks for coming!');
      },

      // Called when there's incoming data on the websocket for this channel
      received(data) {
        switch (data.context) {
          case 'message':
            this.renderMessage(data);
            break;
          case 'typing':
            this.refreshTypingText(data);
            break;
          case 'refresh_player_roster':
            this.refreshPlayerRoster(data);
            break;
          case 'draw':
            this.draw(data);
            break;
          case 'clear':
            this.clearCanvas();
            break;
          case 'refresh_timer':
            this.refreshTimeRemaining(data);
            break;
          case 'award_points':
            this.awardPoints(data);
            break;
        }
      },

      // Broadcasts the hash provided as a parameter to all subscribers/consumers
      // of the current channel.
      //
      // @param {JSON} data - payload to be sent over to the server.
      emit(data) {
        // Calls 'RoomChannel#received(data)' on the server.
        channel.perform('received', data);
      },

      renderMessage(data) {
        let chat = document.querySelector('.message-container');
        let message = null;
        if (data.connection_message) {
          // connection status message
          if (data.message.endsWith('has left the chat.')) {
            document.querySelector(`.player-card[id='${data.user_id}']`).remove();
          }
          message = `
            <li>
              <p class="message">
                ${data.message}
              </p>
            </li>
          `;
        } else if (data.user_name) {
          // player message
          message = `
            <li>
              <p class="message">
                <b>${data.user_name}:</b>
                <span>&nbsp;${data.message}</span>
              </p>
            </li>
          `;
        } else {
          // player guess
          message = `
            <li>
              <p class="message">
                <b>${data.message}</b>
              </p>
            </li>
          `;
        }
        chat.insertAdjacentHTML("beforeend", message);
        chat.scrollTo({
          top: chat.scrollHeight,
          left: 0,
          behavior: 'smooth'
        });
      },

      refreshTypingText(data) {
        if (data.typing) {
          typingList.push(data.user_name);
        } else {
          typingList = typingList.filter((name) => {
            return name !== data.user_name;
          });
        }
        let text = '';
        if (typingList.length > 0) {
          text = `${typingList.join(', ')} ${typingList.length === 1 ? "is" : "are"} typing...`;
        }
        document.querySelector('.typing-message > p > i').innerText = text;
      },

      refreshPlayerRoster(data) {
        const range = document.createRange();
        let players = [];
        data.users.forEach((user, index) => {
          let playerCardHTML = `
            <li class="player-card" id="${user.id}">
              <div>
                <p class="position">${index + 1}</p>
                <p>
                  <b class="name">${user.name} <span>${((userId === user.id) ? '(you)' : '')}</span></b>
                  <br>
                  <span class="score">${user.score} PTS</span>
                </p>
              </div>
              ${(user.id === data.drawer_id) ?
                `<i class="fa fa-pencil"></i>` : ""}
            </li>
          `;
          const playerCard = range.createContextualFragment(playerCardHTML);
          players.push(playerCard);
        });
        document.querySelector('.player-container').replaceChildren(...players);
        this.refreshGameOptionVisibility(data.drawer_id);
      },

      refreshGameOptionVisibility(id) {
        let startMatchButton = document.querySelector('#start-game');
        let drawingPalette = document.querySelector('#drawing-palette');
        if (userId === id) {
          startMatchButton.classList.remove('hidden');
          drawingPalette.classList.remove('hidden');
        } else {
          startMatchButton.classList.add('hidden');
          drawingPalette.classList.add('hidden');
        }
      },

      draw(data) {
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.strokeStyle = `#${data.color}`;


        ctx.beginPath();
        ctx.moveTo(data.start_x, data.start_y);
        ctx.lineTo(data.end_x, data.end_y);
        ctx.stroke(); // draw it!
      },

      clearCanvas() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      },

      refreshTimeRemaining(data) {
        roundStarted = (data.seconds !== 15);
        document.querySelector('#time-remaining').innerText = `${data.seconds}s`;
      }
    });

    /* Utilities */
    let roundStarted = false;
    const userId = parseInt(document.querySelector('.player-container').id);
    const getNameFromId = (id) => {
      return document
        .querySelector(`.player-card[id='${id}'] > div > p > b`)
        .innerHTML.replace(/ <span>.*<\/span>/g, '');
    };

    /* Palette */
    const clearButton = document.querySelector('.palette-element__clear-button');
    const paintColorOptions = document.querySelectorAll('.palette-element__color');
    let selectedColorOption = paintColorOptions[0];
    selectedColorOption.classList.toggle('palette-element--selected');

    const getSelectedColor = () => {
      return selectedColorOption ? selectedColorOption.id : 'black';
    };

    paintColorOptions.forEach((element) => {
      element.addEventListener('click', (event) => {
        selectedColorOption.classList.toggle('palette-element--selected');
        selectedColorOption = event.target;
        selectedColorOption.classList.toggle('palette-element--selected');
      })
    });
    clearButton.addEventListener('click', () => {
      channel.emit({
        context: 'clear'
      })
    });

    /* Drawing */
    let canvas = document.querySelector('canvas');
    let offset = canvas.getBoundingClientRect();
    let ctx = canvas.getContext('2d');
    let isDrawing = false;
    let startX, startY, endX, endY;

    // let undoButton = document.querySelector('.palette-element__undo-button');
    // let redoButton = document.querySelector('.palette-element__redo-button');
    // let undoData = [];
    // let redoData = [];

    // const saveState = () => {
    //   undoData.push(canvas.toDataURL());
    //   console.log(undoData);
    //   toggleUndoVisibility();
    //   console.log('state saved');
    // };

    // // pre: undoData.length >= 1
    // const undoState = () => {
    //   redoData.unshift(undoData.shift());
    //   if (undoData.length == 0) {
    //     ctx.clearRect(0, 0, canvas.width, canvas.height);
    //   } else {
    //     let dataURL = undoData[0];
    //     let img = document.createElement('img');
    //     img.src = dataURL;
    //     img.addEventListener('load', () => {
    //       ctx.drawImage(img, 0, 0);
    //     });
    //   }
    //   toggleUndoVisibility();
    // };
    // // pre: redoData.length >= 1
    // const redoState = () => {
    //   undoData.unshift(redoData.shift());

    // };

    // const toggleUndoVisibility = () => {
    //   if (undoData.length == 0) {
    //     undoButton.classList.add('hidden');
    //   } else {
    //     undoButton.classList.remove('hidden');
    //   }
    //   if (redoData.length == 0) {
    //     redoButton.classList.add('hidden');
    //   } else {
    //     redoButton.classList.remove('hidden');
    //   }
    // };

    // undoButton.addEventListener('click', () => {
    //   undoState();
    // });
    // redoButton.addEventListener('click', () => {
    //   restoreState();
    // })

    // Returns distance between point (x1, y1) and point (x2, y2)
    const pointDistance = (x1, y1, x2, y2) => {
      return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    };

    window.addEventListener("resize", () => {
      offset = canvas.getBoundingClientRect();
    });

    canvas.addEventListener('mouseleave', () => {
      isDrawing = false;
    });
    canvas.addEventListener('mouseup', () => {
      isDrawing = false;
      // saveState();
    });
    canvas.addEventListener('mousedown', (event) => {
      isDrawing = true;
      const scaleX = canvas.width / offset.width;
      const scaleY = canvas.height / offset.height;

      startX = (event.clientX - offset.left) * scaleX;
      startY = (event.clientY - offset.top) * scaleY;
    });
    canvas.addEventListener('mousemove', (event) => {
      if (isDrawing) {
        const scaleX = canvas.width / offset.width;
        const scaleY = canvas.height / offset.height;

        endX = (event.clientX - offset.left) * scaleX;
        endY = (event.clientY - offset.top) * scaleY;

        if(pointDistance(startX, startY, endX, endY) > 2) {
          channel.emit({
            context: 'draw',
            color: getSelectedColor(),
            start_x: startX,
            start_y: startY,
            end_x: endX,
            end_y: endY
          })
          startX = endX;
          startY = endY;
        }
      }
    });

    /* Messaging */
    const chatInput = document.querySelector('input#chat_input');
    let typingList = [];
    let isTyping = false;

    chatInput.addEventListener('keydown', (event) => {
      if (!isTyping) {
        isTyping = true;
        channel.emit({
          context: 'typing',
          user_name: getNameFromId(userId),
          typing: isTyping
        });
        setTimeout(() => {
          isTyping = false;
          channel.emit({
            context: 'typing',
            user_name: getNameFromId(userId),
            typing: isTyping
          });
        }, 1000);
      }

      if (event.code === 'Enter') {
        event.preventDefault();
        // If the drawing palette is visible, it means that it's our turn to draw.
        // Therefore, anything we type in the chat should NOT be counted as a guess.
        const isDrawing = !document.querySelector('#drawing-palette').classList.contains('hidden');
        isTyping = false;
        channel.emit({
          context: 'typing',
          user_name: getNameFromId(userId),
          typing: isTyping
        });
        channel.emit({
          context: 'message',
          user_id: userId,
          user_name: getNameFromId(userId),
          message: event.target.value,
          is_guess: (roundStarted && !isDrawing),
          point_award: getSecondsRemaining(),
        });
        event.target.value = '';
      }
    });

    /* Turn based mechanics */
    const getSecondsRemaining = () => {
      return parseInt(document.querySelector('#time-remaining').innerText);
    };

    document.querySelector('#start-game').addEventListener('click', (event) => {
      event.preventDefault();
      let word = prompt('Enter a word:').replace(/\W/g, '').toLowerCase();
      document.querySelector('#start-game').classList.add('hidden');
      channel.emit({ context: 'start', current_word: word });
      console.log('start');
      roundStarted = true;
      const interval = setInterval(() => {
        // This is being placed in the interval so that it will set correctly if
        // the user currently drawing refreshes their tab.
        roundStarted = true;
        console.log('tic');
        let seconds = getSecondsRemaining();
        if (seconds === 0) {
          roundStarted = false;
          console.log('stop');
          window.clearInterval(interval);
          channel.emit({ context: 'stop' })
        } else {
          channel.emit({ context: 'refresh_timer', seconds: (seconds - 1) })
        }
      }, 1000);
    });
  }
})();
