import { useEffect, useState } from "preact/hooks";
import { getTracksByName, playTrackID } from "../../../api/jellyfin/api";
import { Station } from "../../../api/jellyfin/models";
import Card from "../../../components/Card";
import Icon from "../../../components/Icon";
import Input from "../../../components/Input";

//todo
let jellyfinUrl = "https://jellyfin.cf";

const Radio = ({
  Name = "",
  AlbumArtist = "",
  Album = "",
  Id = "",
  ProductionYear = 0,
}) => {
  return (
    <div class="bg-app-secondary shadow-m p-5 border border-app-border flex flex-col relative rounded-xl">
      <img
        class="w-10 h-10 rounded-full bg-white border-app-border border absolute -right-2 -top-2 shadow-xl"
        src={ jellyfinUrl + "/Items/" + Id + "/Images/Primary?fillHeight=200&fillWidth=200&quality=96" }
      />
      <div class="font-normal max-w-[80%] -mt-1 mb-2 truncate">{Name}</div>
      <div class="font-thin text-sm text-gray-400">
        {AlbumArtist} • {Album} • {ProductionYear}
      </div>
      <div class="bg-green-600 text-white w-10 h-10 rounded-full absolute flex -bottom-2 -right-2">
        <div class="mt-[9px] ml-[5px]">
          <Icon
            onClick={() => playTrackID(Id)}
            name="play"
          />
        </div>
        {/* <Icon name="save" /> */}
      </div>
    </div>
  );
};

export default () => {
  const [radios, setRadios] = useState<Station[]>([]);

  return (
    <div class="mb-[150px]">
      <Card title="Jellyfin" subtitle="application">
        <Input
          onSubmit={(e) => {
            getTracksByName(e).then(setRadios);
          }}
          value=""
          placeholder="Search jellyfin"
          icon="search"
        />
        {radios.length > 0 && (
          <div class="grid md:grid-cols-2 grid-cols-1 xl:grid-cols-5 gap-8 mt-10">
            {radios.map((radio) => (
              <Radio {...radio}></Radio>
            ))}
          </div>
        )}
        {radios.length == 0 && (
          <div class="text-app-text-secondary text-xl mt-2 flex-col flex w-full items-center p-5">
              <Icon name="close" />
              Results empty.
          </div>
        )}
      </Card>
    </div>
  );
};
